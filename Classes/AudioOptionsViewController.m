//
//  AudioOptionsViewController.m
//  CalaosHome
//
//  Created by Raoul on 02/05/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "AudioOptionsViewController.h"
#import "CalaosRequest.h"
#import "vorbisenc.h"

@implementation AudioOptionsViewController
@synthesize buttonPlay, buttonSend, buttonStop, buttonRecord, progress, loader, playerId;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)encodeVorbis:(NSString *)soundFile
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *oggFile = [docsDir stringByAppendingPathComponent:@"calaos_msg.ogg"];
    
    #define READ 1024
    signed char readbuffer[READ*4+44]; /* out of the data segment, not the stack */
    
    ogg_stream_state os; /* take physical pages, weld into a logical
                          stream of packets */
    ogg_page         og; /* one Ogg bitstream page.  Vorbis packets are inside */
    ogg_packet       op; /* one raw packet of data for decode */
    
    vorbis_info      vi; /* struct that stores all the static vorbis bitstream
                          settings */
    vorbis_comment   vc; /* struct that stores all the user comments */
    
    vorbis_dsp_state vd; /* central working state for the packet->PCM decoder */
    vorbis_block     vb; /* local working space for packet->PCM decode */
    
    int eos=0,ret;
    int i, founddata;
    
    /* we cheat on the WAV header; we just bypass the header and never
     verify that it matches 16bit/stereo/44.1kHz.  This is just an
     example, after all. */
    
    FILE *fpin = fopen([soundFile UTF8String], "r");
    FILE *fpout = fopen([oggFile UTF8String], "w+");
    
    readbuffer[0] = '\0';
    for (i=0, founddata=0; i<30 && ! feof(stdin) && ! ferror(stdin); i++)
    {
        fread(readbuffer,1,2,fpin);
        
        if ( ! strncmp((char*)readbuffer, "da", 2) ){
            founddata = 1;
            fread(readbuffer,1,6,fpin);
            break;
        }
    }
    
    /********** Encode setup ************/
    
    vorbis_info_init(&vi);
    
    /* choose an encoding mode.  A few possibilities commented out, one
     actually used: */
    
    /*********************************************************************
     Encoding using a VBR quality mode.  The usable range is -.1
     (lowest quality, smallest file) to 1. (highest quality, largest file).
     Example quality mode .4: 44kHz stereo coupled, roughly 128kbps VBR
     
     ret = vorbis_encode_init_vbr(&vi,2,44100,.4);
     
     ---------------------------------------------------------------------
     
     Encoding using an average bitrate mode (ABR).
     example: 44kHz stereo coupled, average 128kbps VBR
     
     ret = vorbis_encode_init(&vi,2,44100,-1,128000,-1);
     
     ---------------------------------------------------------------------
     
     Encode using a quality mode, but select that quality mode by asking for
     an approximate bitrate.  This is not ABR, it is true VBR, but selected
     using the bitrate interface, and then turning bitrate management off:
     
     ret = ( vorbis_encode_setup_managed(&vi,2,44100,-1,128000,-1) ||
     vorbis_encode_ctl(&vi,OV_ECTL_RATEMANAGE2_SET,NULL) ||
     vorbis_encode_setup_init(&vi));
     
     *********************************************************************/
    
    ret=vorbis_encode_init_vbr(&vi,2,44100,0.1);
    
    /* do not continue if setup failed; this can happen if we ask for a
     mode that libVorbis does not support (eg, too low a bitrate, etc,
     will return 'OV_EIMPL') */
    
    if(ret)
    {
        NSLog(@"Encode error! vorbis_encode_init_vbr failed");
        
        [self performSelectorOnMainThread:@selector(encodeVorbisDone:) withObject:nil waitUntilDone:NO];
        
        [pool release];
        
        return;
    }
    
    /* add a comment */
    vorbis_comment_init(&vc);
    vorbis_comment_add_tag(&vc,"ENCODER","Calaos Home libvorbis");
    
    /* set up the analysis state and auxiliary encoding storage */
    vorbis_analysis_init(&vd,&vi);
    vorbis_block_init(&vd,&vb);
    
    /* set up our packet->stream encoder */
    /* pick a random serial number; that way we can more likely build
     chained streams just by concatenation */
    srand(time(NULL));
    ogg_stream_init(&os,rand());
    
    /* Vorbis streams begin with three headers; the initial header (with
     most of the codec setup parameters) which is mandated by the Ogg
     bitstream spec.  The second header holds any comment fields.  The
     third header holds the bitstream codebook.  We merely need to
     make the headers, then pass them to libvorbis one at a time;
     libvorbis handles the additional Ogg bitstream constraints */
    
    {
        ogg_packet header;
        ogg_packet header_comm;
        ogg_packet header_code;
        
        vorbis_analysis_headerout(&vd,&vc,&header,&header_comm,&header_code);
        ogg_stream_packetin(&os,&header); /* automatically placed in its own
                                           page */
        ogg_stream_packetin(&os,&header_comm);
        ogg_stream_packetin(&os,&header_code);
        
        /* This ensures the actual
         * audio data will start on a new page, as per spec
         */
        while(!eos){
            int result=ogg_stream_flush(&os,&og);
            if(result==0)break;
            fwrite(og.header,1,og.header_len,fpout);
            fwrite(og.body,1,og.body_len,fpout);
        }
        
    }
    
    while(!eos){
        long i;
        long bytes=fread(readbuffer,1,READ*4,fpin); /* stereo hardwired here */
        
        if(bytes==0){
            /* end of file.  this can be done implicitly in the mainline,
             but it's easier to see here in non-clever fashion.
             Tell the library we're at end of stream so that it can handle
             the last frame and mark end of stream in the output properly */
            vorbis_analysis_wrote(&vd,0);
            
        }else{
            /* data to encode */
            
            /* expose the buffer to submit data */
            float **buffer=vorbis_analysis_buffer(&vd,READ);
            
            /* uninterleave samples */
            for(i=0;i<bytes/4;i++){
                buffer[0][i]=((readbuffer[i*4+1]<<8)|
                              (0x00ff&(int)readbuffer[i*4]))/32768.f;
                buffer[1][i]=((readbuffer[i*4+3]<<8)|
                              (0x00ff&(int)readbuffer[i*4+2]))/32768.f;
            }
            
            /* tell the library how much we actually submitted */
            vorbis_analysis_wrote(&vd,i);
        }
        
        /* vorbis does some data preanalysis, then divvies up blocks for
         more involved (potentially parallel) processing.  Get a single
         block for encoding now */
        while(vorbis_analysis_blockout(&vd,&vb)==1){
            
            /* analysis, assume we want to use bitrate management */
            vorbis_analysis(&vb,NULL);
            vorbis_bitrate_addblock(&vb);
            
            while(vorbis_bitrate_flushpacket(&vd,&op)){
                
                /* weld the packet into the bitstream */
                ogg_stream_packetin(&os,&op);
                
                /* write out pages (if any) */
                while(!eos){
                    int result=ogg_stream_pageout(&os,&og);
                    if(result==0)break;
                    fwrite(og.header,1,og.header_len,fpout);
                    fwrite(og.body,1,og.body_len,fpout);
                    
                    /* this could be set above, but for illustrative purposes, I do
                     it here (to show that vorbis does know where the stream ends) */
                    
                    if(ogg_page_eos(&og))eos=1;
                }
            }
        }
    }
    
    /* clean up and exit.  vorbis_info_clear() must be called last */
    
    ogg_stream_clear(&os);
    vorbis_block_clear(&vb);
    vorbis_dsp_clear(&vd);
    vorbis_comment_clear(&vc);
    vorbis_info_clear(&vi);
    
    /* ogg_page and ogg_packet structs always point to storage in
     libvorbis.  They're never freed or manipulated directly */
    
    NSLog(@"Encoding done.");
    
    encodingDone = YES;
    
    [self performSelectorOnMainThread:@selector(encodeVorbisDone:) withObject:oggFile waitUntilDone:NO];
    
    [pool release];
}

- (IBAction)buttonPlay:(id) sender
{
    if (!audioRecorder.recording)
    {
        buttonStop.enabled = YES;
        buttonRecord.enabled = NO;
        
        if (audioPlayer)
            [audioPlayer release];
        NSError *error;
        
        audioPlayer = [[AVAudioPlayer alloc] 
                       initWithContentsOfURL:audioRecorder.url                                    
                       error:&error];
        
        audioPlayer.delegate = self;
        
        if (error)
        {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
        else
        {
            [audioPlayer play];
            
            timerProgress = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
        }
    }
}

- (IBAction)buttonStop:(id) sender
{
    buttonStop.enabled = NO;
    buttonPlay.enabled = YES;
    buttonRecord.enabled = YES;
    buttonSend.enabled = YES;
    
    if (audioRecorder.recording)
    {
        [audioRecorder stop];
        
        encodingDone = NO;
    } 
    else if (audioPlayer.playing) 
    {
        [audioPlayer stop];
        [timerProgress invalidate];
    }
}

- (IBAction)buttonRecord:(id) sender
{
    if (!audioRecorder.recording)
    {
        buttonPlay.enabled = NO;
        buttonStop.enabled = YES;
        buttonSend.enabled = NO;
        [audioRecorder recordForDuration:30.0]; //Max 30s of recording allowed!
        
        [progress setProgress:0];
    }
}

- (void)sendingDone:(NSString *)res
{
    loader.hidden = YES;
    [loader stopAnimating];
    
    buttonPlay.enabled = YES;
    buttonRecord.enabled = YES;
    buttonSend.enabled = YES;
}

- (void)encodeVorbisDone:(NSString *)oggFile
{
    if (oggFile)
    {
        CalaosRequest *calaos = [CalaosRequest sharedInstance];
        [calaos sendAudioFile:oggFile toPlayer:playerId withDelegate:self andDoneSelector:@selector(sendingDone:)];
    }
    else
    {
        NSLog(@"Failed to encode...");
        
        loader.hidden = YES;
        [loader stopAnimating];
    }
}

- (IBAction)buttonSend:(id) sender
{       
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"calaos_msg.wav"];
    NSString *oggFilePath = [docsDir stringByAppendingPathComponent:@"calaos_msg.ogg"];
    
    loader.hidden = NO;
    [loader startAnimating];
    
    buttonPlay.enabled = NO;
    buttonRecord.enabled = NO;
    buttonSend.enabled = NO;
    
    if (!encodingDone)
        [self performSelectorInBackground:@selector(encodeVorbis:) withObject:soundFilePath];
    else
        [self encodeVorbisDone:oggFilePath];
}

-(void)updateProgress
{
    progress.progress = audioPlayer.currentTime / audioPlayer.duration;
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    buttonRecord.enabled = YES;
    buttonStop.enabled = NO;
    buttonPlay.enabled = YES;
    [progress setProgress:0];
    
    [timerProgress invalidate];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player 
                                error:(NSError *)error
{
    NSLog(@"Decode Error occurred");
}

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder 
                          successfully:(BOOL)flag
{
    NSLog(@"Record finish successfully");
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder 
                                  error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    buttonSend.enabled = NO;
    buttonPlay.enabled = NO;
    buttonRecord.enabled = YES;
    buttonStop.enabled = NO;
    loader.hidden = YES;
    [progress setProgress:0];
    
    NSArray *dirPaths;
    NSString *docsDir;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"calaos_msg.wav"];
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    NSDictionary *recordSettings = [NSDictionary 
                                    dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithInt:AVAudioQualityMin], AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:16], AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                    [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                    [NSNumber numberWithBool:NO] ,AVLinearPCMIsFloatKey,
                                    
                                    /*[NSNumber numberWithInt:kAudioFormatAppleLossless] ,AVFormatIDKey,
                                    [NSNumber numberWithFloat:44100.0] ,AVSampleRateKey,
                                    [NSNumber numberWithInt: 2] ,AVNumberOfChannelsKey,
                                    [NSNumber numberWithInt:16] ,AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:NO] ,AVLinearPCMIsBigEndianKey,
                                    [NSNumber numberWithBool:NO] ,AVLinearPCMIsFloatKey,
                                    
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                    [NSNumber numberWithFloat:11025.0],             AVSampleRateKey,
                                    [NSNumber numberWithInt:1],                     AVNumberOfChannelsKey,
                                    [NSNumber numberWithInt:16],                    AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithBool:YES],                  AVLinearPCMIsBigEndianKey,
                                    [NSNumber numberWithBool:NO],                   AVLinearPCMIsFloatKey,*/
                                    
                                    nil];
    
    NSError *error = nil;
    
    audioRecorder = [[AVAudioRecorder alloc]
                     initWithURL:soundFileURL
                     settings:recordSettings
                     error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } 
    else 
    {
        [audioRecorder prepareToRecord];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.buttonRecord = nil;
    self.buttonPlay = nil;
    self.buttonSend = nil;
    self.buttonStop = nil;
    self.loader = nil;
    self.progress = nil;
    
    if (audioPlayer)
        [audioPlayer release];
    audioPlayer = nil;
    
    if (audioRecorder)
        [audioRecorder release];
    audioRecorder = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
