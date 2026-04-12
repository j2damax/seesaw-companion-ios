warning: (arm64) /Users/jayampathyicloud.com/Library/Developer/Xcode/DerivedData/SeeSaw-drxzukhunglnfxffaoobjgakabns/Build/Products/Debug-iphoneos/SeeSaw.app/SeeSaw empty dSYM file detected, dSYM was created with an executable with no debug info.
12.11.0 - [GoogleUtilities/AppDelegateSwizzler][I-SWZ001014] App Delegate does not conform to UIApplicationDelegate protocol.
[Firebase/Crashlytics] Version 12.11.0
numANECores: Unknown aneSubType
[2026-04-12T05:29:46.728Z] [DEBUG] [PrivacyPipelineService.init:60] init: objectDetectionModel loaded=true
void * _Nullable NSMapGet(NSMapTable * _Nonnull, const void * _Nullable): map table argument is NULL
Unknown client: SeeSaw
(Fig) signalled err=-12710 at <>:601
(Fig) signalled err=-12710 at <>:601
(Fig) signalled err=-12710 at <>:601
<<<< FigXPCUtilities >>>> signalled err=-17281 at <>:308
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:569) - (err=-17281)
[2026-04-12T05:29:54.816Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-12T05:29:55.126Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=48180, exifOrientation=6
[2026-04-12T05:29:55.127Z] [DEBUG] [CompanionViewModel.runDetectionPreview:265] runDetectionPreview: start, jpegBytes=48180
[2026-04-12T05:29:55.226Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-12T05:29:55.227Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-12T05:29:55.311Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-12T05:29:55.319Z] [DEBUG] [PrivacyPipelineService.parseDetections:307] Stage 3 – object detection (recognized): count=3, items=["shelf@46%", "table@95%", "sofa@95%"]
[2026-04-12T05:29:55.319Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:281] Stage 3 – object detection (boxes): count=3, items=["shelf@46%", "table@95%", "sofa@95%"]
[2026-04-12T05:29:55.320Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=3, labels=["shelf", "table", "sofa"]
[2026-04-12T05:29:55.331Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=49223
[2026-04-12T05:29:55.331Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=203ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:29:55.331Z] [DEBUG] [CompanionViewModel.runDetectionPreview:294] runDetectionPreview: done, detectionCount=3, blurredBytes=49223
[2026-04-12T05:29:58.677Z] [DEBUG] [CompanionViewModel.runFullPipeline:305] runFullPipeline: start, mode=onDevice, jpegBytes=49223, childAge=10
[2026-04-12T05:29:58.677Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:319] runOnDevicePipeline: start
[2026-04-12T05:29:58.681Z] [DEBUG] [PrivacyPipelineService.process:74] Stage 0 – input: imageSize=(480.0, 360.0), childAge=10
[2026-04-12T05:29:58.681Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(480.0, 360.0)
[2026-04-12T05:29:58.687Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-12T05:29:58.738Z] [DEBUG] [PrivacyPipelineService.parseDetections:307] Stage 3 – object detection (recognized): count=0, items=[]
[2026-04-12T05:29:58.738Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithModel:271] Stage 3 – object detection: labels=[]
[2026-04-12T05:29:58.823Z] [DEBUG] [PrivacyPipelineService.classifyScene:381] Stage 4 – scene classification: labels=[]
[2026-04-12T05:29:58.823Z] [DEBUG] [PrivacyPipelineService.recognizeSpeech:398] Stage 5 – speech recognition: skipped: no audio data provided
[2026-04-12T05:29:58.823Z] [DEBUG] [PrivacyPipelineService.process:141] Pipeline benchmark: faceDetect=3ms blur=2ms yolo=135ms scene=135ms stt=135ms piiScrub=0ms total=143ms
[2026-04-12T05:29:58.823Z] [DEBUG] [PrivacyPipelineService.process:142] Stage 6 – output: objects=[], scene=[], hasTranscript=false
[2026-04-12T05:29:58.824Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=143ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:29:58.824Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:335] runOnDevicePipeline: privacy done, objects=[]
[2026-04-12T05:29:58.855Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
[2026-04-12T05:30:07.199Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=8, textLen=248, hasQuestion=true, isEnding=false
[2026-04-12T05:30:07.201Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:363] runOnDevicePipeline: story generated in 8376ms, ttft=4680ms
[2026-04-12T05:30:07.201Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:364] beat[0] storyText: Vihas, imagine standing at the edge of a vast, mysterious forest. The trees tower above you, their leaves whispering secrets in the gentle breeze. In your hand, you hold a small lantern, its warm glow casting flickering shadows on the forest floor.
[2026-04-12T05:30:07.201Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:365] beat[0] question: What do you feel most curious about in the forest?
[2026-04-12T05:30:07.407Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=248
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
          IPCAUClient.cpp:139   IPCAUClient: can't connect to server (-66748)
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
nw_connection_copy_protocol_metadata_internal_block_invoke [C3] Client called nw_connection_copy_protocol_metadata_internal on unconnected nw_connection
nw_connection_copy_protocol_metadata_internal_block_invoke [C3] Client called nw_connection_copy_protocol_metadata_internal on unconnected nw_connection
nw_connection_copy_protocol_metadata_internal_block_invoke [C3] Client called nw_connection_copy_protocol_metadata_internal on unconnected nw_connection
nw_connection_copy_connected_local_endpoint_block_invoke [C3] Client called nw_connection_copy_connected_local_endpoint on unconnected nw_connection
nw_connection_copy_connected_remote_endpoint_block_invoke [C3] Client called nw_connection_copy_connected_remote_endpoint on unconnected nw_connection
[2026-04-12T05:30:25.998Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=248
[2026-04-12T05:30:25.999Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=50
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:30:29.291Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=50
[2026-04-12T05:30:29.581Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-12T05:30:29.592Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-12T05:30:35.074Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=2, tokensRedacted=0
[2026-04-12T05:30:35.661Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=10, tokensRedacted=0
[2026-04-12T05:30:35.676Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=12, tokensRedacted=0
[2026-04-12T05:30:36.208Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=18, tokensRedacted=0
[2026-04-12T05:30:36.838Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=22, tokensRedacted=0
[2026-04-12T05:30:36.999Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=25, tokensRedacted=0
[2026-04-12T05:30:37.324Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=28, tokensRedacted=0
[2026-04-12T05:30:37.492Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=32, tokensRedacted=0
[2026-04-12T05:30:37.755Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=40, tokensRedacted=0
[2026-04-12T05:30:39.404Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=41, tokensRedacted=0
[2026-04-12T05:30:44.813Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=2899200
[2026-04-12T05:30:44.813Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=Most curious about forests in the animals
[2026-04-12T05:30:44.813Z] [DEBUG] [CompanionViewModel.listenForAnswer:508] listenForAnswer: answer='Most curious about forests in the animals', length=41
[2026-04-12T05:30:44.819Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
[2026-04-12T05:30:51.492Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=7, textLen=202, hasQuestion=true, isEnding=false
[2026-04-12T05:30:51.492Z] [DEBUG] [CompanionViewModel.continueStoryLoop:437] beat[0] storyText: Vihas, as you step deeper into the forest, you notice a family of rabbits hopping playfully between the trees. Their fluffy tails twitch with curiosity as they pause to watch you with wide, gentle eyes.
[2026-04-12T05:30:51.492Z] [DEBUG] [CompanionViewModel.continueStoryLoop:438] beat[0] question: Do you want to follow the rabbits to meet other forest friends?
[2026-04-12T05:30:51.555Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=202
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:31:04.893Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=202
[2026-04-12T05:31:04.893Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=63
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:31:08.813Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=63
[2026-04-12T05:31:09.108Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-12T05:31:09.124Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-12T05:31:10.927Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=3, tokensRedacted=0
[2026-04-12T05:31:11.547Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=5, tokensRedacted=0
[2026-04-12T05:31:11.736Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=10, tokensRedacted=0
[2026-04-12T05:31:11.931Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=13, tokensRedacted=0
[2026-04-12T05:31:12.126Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=18, tokensRedacted=0
[2026-04-12T05:31:12.425Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-12T05:31:14.119Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-12T05:31:24.814Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=2995200
[2026-04-12T05:31:24.814Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-12T05:31:24.814Z] [DEBUG] [CompanionViewModel.listenForAnswer:508] listenForAnswer: answer='Yes I want to meet them', length=23
[2026-04-12T05:31:24.825Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
[2026-04-12T05:31:32.252Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=8, textLen=224, hasQuestion=true, isEnding=false
[2026-04-12T05:31:32.252Z] [DEBUG] [CompanionViewModel.continueStoryLoop:437] beat[1] storyText: Vihas, with the rabbits leading the way, you weave through the forest, discovering a hidden glade filled with colorful wildflowers swaying in the breeze. Butterflies dance around you, their wings shimmering like tiny jewels.
[2026-04-12T05:31:32.252Z] [DEBUG] [CompanionViewModel.continueStoryLoop:438] beat[1] question: Do you want to join the rabbits in their game or explore the glade further?
[2026-04-12T05:31:32.310Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=224
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:31:46.300Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=224
[2026-04-12T05:31:46.300Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=75
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:31:50.556Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=75
[2026-04-12T05:31:50.854Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-12T05:31:50.857Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-12T05:31:55.068Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=3, tokensRedacted=0
[2026-04-12T05:31:55.366Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=5, tokensRedacted=0
[2026-04-12T05:31:55.670Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=10, tokensRedacted=0
[2026-04-12T05:31:55.872Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=13, tokensRedacted=0
[2026-04-12T05:31:56.078Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=16, tokensRedacted=0
[2026-04-12T05:31:56.268Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=21, tokensRedacted=0
[2026-04-12T05:31:56.569Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=24, tokensRedacted=0
[2026-04-12T05:31:58.265Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=24, tokensRedacted=0
[2026-04-12T05:32:06.651Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=3014400
[2026-04-12T05:32:06.653Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-12T05:32:06.654Z] [DEBUG] [CompanionViewModel.listenForAnswer:508] listenForAnswer: answer='Yes I want to explore it', length=24
[2026-04-12T05:32:06.659Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
[2026-04-12T05:32:14.574Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=8, textLen=187, hasQuestion=true, isEnding=false
[2026-04-12T05:32:14.574Z] [DEBUG] [CompanionViewModel.continueStoryLoop:437] beat[2] storyText: Vihas, as you wander through the glade, you come across a small, sparkling stream. Sunlight dances on the water's surface, creating a magical path that seems to lead to even more wonders.
[2026-04-12T05:32:14.574Z] [DEBUG] [CompanionViewModel.continueStoryLoop:438] beat[2] question: Do you want to follow the stream and discover where it flows next?
[2026-04-12T05:32:14.641Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=187
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:32:27.661Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=187
[2026-04-12T05:32:27.662Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=66
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:32:31.813Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=66
[2026-04-12T05:32:32.100Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-12T05:32:32.109Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-12T05:32:33.509Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=3, tokensRedacted=0
[2026-04-12T05:32:33.729Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=6, tokensRedacted=0
[2026-04-12T05:32:34.245Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=15, tokensRedacted=0
[2026-04-12T05:32:34.739Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=19, tokensRedacted=0
[2026-04-12T05:32:34.919Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=26, tokensRedacted=0
[2026-04-12T05:32:35.441Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=29, tokensRedacted=0
[2026-04-12T05:32:35.735Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=34, tokensRedacted=0
[2026-04-12T05:32:35.926Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=37, tokensRedacted=0
[2026-04-12T05:32:37.518Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=38, tokensRedacted=0
[2026-04-12T05:32:48.095Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=3052800
[2026-04-12T05:32:48.095Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-12T05:32:48.095Z] [DEBUG] [CompanionViewModel.listenForAnswer:508] listenForAnswer: answer='Yes it's follow the stream on discover', length=38
[2026-04-12T05:32:48.102Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
[2026-04-12T05:32:55.916Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=8, textLen=188, hasQuestion=true, isEnding=false
[2026-04-12T05:32:55.917Z] [DEBUG] [CompanionViewModel.continueStoryLoop:437] beat[3] storyText: Vihas, as you follow the stream, you come across a small, shimmering waterfall. Rainbows arc beautifully in the sunlight, and you feel as though you've stepped into a magical hidden world.
[2026-04-12T05:32:55.917Z] [DEBUG] [CompanionViewModel.continueStoryLoop:438] beat[3] question: Do you want to explore the waterfall or find a cozy spot nearby?
[2026-04-12T05:32:55.978Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=188
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:33:08.303Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=188
[2026-04-12T05:33:08.304Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=64
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:33:12.619Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=64
[2026-04-12T05:33:12.898Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-12T05:33:12.903Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-12T05:33:15.011Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=3, tokensRedacted=0
[2026-04-12T05:33:15.514Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=7, tokensRedacted=0
[2026-04-12T05:33:15.908Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=9, tokensRedacted=0
[2026-04-12T05:33:16.209Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=16, tokensRedacted=0
[2026-04-12T05:33:16.510Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=20, tokensRedacted=0
[2026-04-12T05:33:16.717Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=26, tokensRedacted=0
[2026-04-12T05:33:17.112Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=30, tokensRedacted=0
[2026-04-12T05:33:17.713Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=34, tokensRedacted=0
[2026-04-12T05:33:18.308Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=39, tokensRedacted=0
[2026-04-12T05:33:18.912Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=46, tokensRedacted=0
[2026-04-12T05:33:19.520Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=50, tokensRedacted=0
[2026-04-12T05:33:19.812Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=52, tokensRedacted=0
[2026-04-12T05:33:20.313Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=59, tokensRedacted=0
[2026-04-12T05:33:21.915Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=61, tokensRedacted=0
[2026-04-12T05:33:28.825Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=3033600
[2026-04-12T05:33:28.825Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-12T05:33:28.826Z] [DEBUG] [CompanionViewModel.listenForAnswer:508] listenForAnswer: answer='Yes let's follow the waterfall and find nearby curious things', length=61
[2026-04-12T05:33:33.427Z] [DEBUG] [CompanionViewModel.continueStoryLoop:437] beat[4] storyText: As you climb the waterfall's misty steps, you hear a faint melody carried by the wind. Following the sound, you discover a hidden grove filled with glowing flowers and a gentle pond.
[2026-04-12T05:33:33.427Z] [DEBUG] [CompanionViewModel.continueStoryLoop:438] beat[4] question: What do you see in the hidden grove?
[2026-04-12T05:33:33.486Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=182
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:33:45.141Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=182
[2026-04-12T05:33:45.143Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=36
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:33:47.297Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=36
[2026-04-12T05:33:47.593Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-12T05:33:47.598Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-12T05:33:50.904Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=2, tokensRedacted=0
[2026-04-12T05:33:51.408Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=8, tokensRedacted=0
[2026-04-12T05:33:51.605Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=15, tokensRedacted=0
[2026-04-12T05:33:51.807Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=18, tokensRedacted=0
[2026-04-12T05:33:52.106Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=22, tokensRedacted=0
[2026-04-12T05:33:52.602Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=29, tokensRedacted=0
[2026-04-12T05:33:52.812Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=35, tokensRedacted=0
[2026-04-12T05:33:53.307Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=42, tokensRedacted=0
[2026-04-12T05:33:53.612Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=28, tokensRedacted=1
[2026-04-12T05:33:53.809Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=29, tokensRedacted=0
[2026-04-12T05:33:54.012Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=30, tokensRedacted=1
[2026-04-12T05:33:54.509Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=31, tokensRedacted=1
[2026-04-12T05:33:54.806Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=32, tokensRedacted=1
[2026-04-12T05:33:56.606Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=35, tokensRedacted=1
[2026-04-12T05:33:57.208Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=42, tokensRedacted=1
[2026-04-12T05:33:57.410Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=44, tokensRedacted=1
[2026-04-12T05:33:57.416Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=49, tokensRedacted=1
[2026-04-12T05:33:57.616Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=52, tokensRedacted=1
[2026-04-12T05:33:58.523Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=59, tokensRedacted=1
[2026-04-12T05:33:58.610Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=60, tokensRedacted=1
[2026-04-12T05:34:00.211Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=60, tokensRedacted=1
[2026-04-12T05:34:01.006Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=3, tokensRedacted=0
[2026-04-12T05:34:01.210Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=5, tokensRedacted=0
[2026-04-12T05:34:01.402Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=10, tokensRedacted=0
[2026-04-12T05:34:01.703Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=13, tokensRedacted=0
[2026-04-12T05:34:02.009Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=20, tokensRedacted=0
[2026-04-12T05:34:02.406Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-12T05:34:02.409Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=28, tokensRedacted=0
[2026-04-12T05:34:02.717Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=2880000
[2026-04-12T05:34:02.719Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=And I want to follow up with the
[2026-04-12T05:34:02.719Z] [DEBUG] [CompanionViewModel.listenForAnswer:508] listenForAnswer: answer='And I want to follow up with', length=28
[2026-04-12T05:34:02.728Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
[2026-04-12T05:34:07.285Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=5, textLen=124, hasQuestion=true, isEnding=false
[2026-04-12T05:34:07.286Z] [DEBUG] [CompanionViewModel.continueStoryLoop:437] beat[0] storyText: As you explore the grove, you find a wise old owl perched on a branch, offering guidance and sharing ancient forest secrets.
[2026-04-12T05:34:07.286Z] [DEBUG] [CompanionViewModel.continueStoryLoop:438] beat[0] question: What advice does the owl give you?
[2026-04-12T05:34:07.347Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=124
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:34:16.187Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=124
[2026-04-12T05:34:16.188Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=34
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:34:18.333Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=34
[2026-04-12T05:34:18.635Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-12T05:34:18.643Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-12T05:34:23.647Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=2, tokensRedacted=0
[2026-04-12T05:34:24.052Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=9, tokensRedacted=0
[2026-04-12T05:34:24.648Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=14, tokensRedacted=0
[2026-04-12T05:34:25.854Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=17, tokensRedacted=0
[2026-04-12T05:34:29.646Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=17, tokensRedacted=0
[2026-04-12T05:34:30.051Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=2, tokensRedacted=0
[2026-04-12T05:34:31.845Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=2, tokensRedacted=0
[2026-04-12T05:34:33.247Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=6, tokensRedacted=0
[2026-04-12T05:34:33.824Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=2899200
[2026-04-12T05:34:33.825Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=Father is
[2026-04-12T05:34:33.825Z] [DEBUG] [CompanionViewModel.listenForAnswer:508] listenForAnswer: answer='Father', length=6
[2026-04-12T05:34:33.835Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
[2026-04-12T05:34:39.871Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=6, textLen=115, hasQuestion=true, isEnding=true
[2026-04-12T05:34:39.872Z] [DEBUG] [CompanionViewModel.continueStoryLoop:437] beat[1] storyText: As the sun begins to set, Vihas feels a warm sense of fulfillment, knowing he has learned so much from his journey.
[2026-04-12T05:34:39.872Z] [DEBUG] [CompanionViewModel.continueStoryLoop:438] beat[1] question: What will Vihas do next?
[2026-04-12T05:34:39.933Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=115
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:34:47.715Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=115
[2026-04-12T05:34:47.716Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=24
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T05:34:49.533Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=24

TEST:
warning: (arm64) /Users/jayampathyicloud.com/Library/Developer/Xcode/DerivedData/SeeSaw-drxzukhunglnfxffaoobjgakabns/Build/Products/Debug-iphoneos/SeeSaw.app/SeeSaw empty dSYM file detected, dSYM was created with an executable with no debug info.
12.11.0 - [GoogleUtilities/AppDelegateSwizzler][I-SWZ001014] App Delegate does not conform to UIApplicationDelegate protocol.
[Firebase/Crashlytics] Version 12.11.0
numANECores: Unknown aneSubType
[2026-04-12T05:37:05.633Z] [DEBUG] [PrivacyPipelineService.init:60] init: objectDetectionModel loaded=true
Test Suite 'All tests' started at 2026-04-12 11:07:06.954.
Test Suite 'All tests' passed at 2026-04-12 11:07:07.029.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.075) seconds
◇ Test run started.
↳ Testing Library Version: 1501
↳ Target Platform: arm64e-apple-ios16.4
◇ Suite DifficultyLevelTests started.
◇ Suite AudioErrorTests started.
◇ Suite PipelineResultTests started.
◇ Suite TransferChunkTests started.
◇ Suite StoryErrorTests started.
◇ Suite PrivacyMetricsInvariantTests started.
◇ Suite WearableTypeTests started.
◇ Suite BookmarkMomentToolTests started.
◇ Suite ChunkBufferTests started.
◇ Suite PrivacyComplianceTests started.
◇ Suite StoryBookmarkStoreTests started.
◇ Suite ScenePayloadPrivacyTests started.
◇ Suite StoryBeatTests started.
◇ Suite UserDefaultsOnboardingTests started.
◇ Suite ChildProfileTests started.
◇ Suite AudioServiceVoiceSettingsTests started.
◇ Suite StoryMetricsStoreTests started.
◇ Suite StoryMetricsEventTests started.
◇ Suite SessionStateTests started.
◇ Suite StoryGenerationModeTests started.
◇ Suite MockAudioServiceTests started.
◇ Suite MockStoryServiceLifecycleTests started.
◇ Suite SwitchSceneToolTests started.
◇ Suite PrivacyMetricsStoreTests started.
◇ Suite SceneContextTests started.
◇ Suite AudioServiceEmptyTextTests started.
◇ Suite ScenePayloadTests started.
◇ Suite PIIScrubberTests started.
◇ Suite TimelineEntryTests started.
◇ Suite AdjustDifficultyToolTests started.
◇ Suite UserDefaultsWearableTypeTests started.
◇ Test synthesisFailed_hasDescription() started.

◇ Test onboardingFilterExcludesMFiCamera() started.
◇ Test allTypesHaveNonEmptyDisplayProperties() started.
◇ Test allCasesHaveDescriptions() started.
◇ Test synthesisFailed_isLocalizedError() started.
◇ Test bluetoothRequirementIsCorrect() started.
◇ Test generationFailedIncludesDetail() started.
◇ Test callAddsBookmarkToStore() started.
◇ Test callReturnsConfirmationString() started.
◇ Test multipleCallsAccumulateBookmarks() started.
◇ Test facesBlurredEqualsFacesDetected() started.
◇ Test metricsAreCodable() started.
◇ Test allCasesCount() started.
◇ Test inOrderReassembly() started.
◇ Test resetClearsBuffer() started.
◇ Test hundredRunsNeverTransmitRawData() started.
◇ Test piiScrubberAndSpeechServiceShareSameLogic() started.
◇ Test resultContainsBothPayloadAndMetrics() started.
◇ Test modelUnavailableHasDescription() started.
◇ Test rawDataTransmittedAlwaysFalse() started.
◇ Test headerParsing() started.
◇ Test payloadContainsNoBoundingBoxes() started.
◇ Test roundTrip() started.
◇ Test rejectsTooShortPacket() started.
◇ Test payloadContainsNoBase64() started.
◇ Test payloadContainsNoDataFields() started.
◇ Test endingFallbackMarkedAsEnding() started.
◇ Test safeFallbackIsNotEnding() started.
◇ Test manualConstructionPreservesFields() started.
◇ Test safeFallbackHasNonEmptyFields() started.
◇ Test termsAndOnboardingFlagsRoundTrip() started.
◇ Test payloadContainsOnlyAllowedKeys() started.
◇ Test pitchMultiplierIsWithinValidRange() started.
◇ Test presetTopicsAreUnique() started.
◇ Test speechRateMultiplierSlowsDownSpeech() started.
◇ Test voiceLanguageResolvesToNonNilVoice() started.
◇ Test sendableConformance() started.
◇ Test pitchMultiplierIsAboveNeutral() started.
◇ Test volumeIsWithinValidRange() started.
◇ Test codableRoundTrip() started.
◇ Test activeStates() started.
◇ Test scanningDisplayTitleIsGeneric() started.
◇ Test addAndRetrieve() started.
◇ Test errorEquality() started.
◇ Test caseIterableContainsAllThreeModes() started.
◇ Test descriptionsAreNonEmpty() started.
◇ Test rawValues() started.
◇ Test connectedStates() started.
◇ Test presetTopicsAreNonEmpty() started.
◇ Test sendableConformance() started.
◇ Test rawValueRoundTrip() started.
◇ Test displayNamesAreNonEmpty() started.
◇ Test invalidRawValueReturnsNil() started.
◇ Test speakRecordsTextsInOrder() started.
◇ Test generateAndEncodeReturnsConfiguredData() started.
◇ Test speakEmptyStringIsRecorded() started.
◇ Test storyBeatSpeaksTextThenQuestion() started.
◇ Test speakRecordsCallCount() started.
◇ Test speechRateIsWithinValidRange() started.
◇ Test resetClearsAllEvents() started.
◇ Test eventCount() started.
◇ Test recordAndRetrieve() started.
◇ Test totalTokensScrubbed() started.
◇ Test sanitisationRateIs100Percent() started.
◇ Test sanitisationRateEmptyStore() started.
◇ Test averageLatencyEmptyStore() started.
◇ Test averageLatency() started.
◇ Test totalFacesDetectedAndBlurred() started.
◇ Test csvExportEmptyStore() started.
◇ Test csvExportContainsHeaderAndRows() started.
◇ Test generateAndEncodeThrowsWhenConfigured() started.
◇ Test constructionFromScenePayload() started.
◇ Test sendableConformance() started.
◇ Test directInitialiserPreservesFields() started.
◇ Test speakWhitespaceDoesNotCrash() started.
◇ Test scenePayloadNeverContainsRawImageData() started.
◇ Test nilTranscriptPreserved() started.
◇ Test speakEmptyStringReturnsImmediately() started.
◇ Test nilTranscriptEncodes() started.
◇ Test scrubRemovesNamePatterns() started.
◇ Test scrubCountsRedactedTokens() started.
◇ Test scrubHandlesMultiplePIITypes() started.
◇ Test scrubPreservesStoryVocabulary() started.
◇ Test scrubRemovesUSZipCodes() started.
◇ Test scrubRemovesStreetAddresses() started.
◇ Test scrubRemovesLongNumbers() started.
◇ Test scrubRemovesEmailAddresses() started.
◇ Test constructionWithEmptyArrays() started.
◇ Test scrubRemovesPhoneNumbers() started.
◇ Test scrubHandlesEmptyString() started.
◇ Test encodesCorrectly() started.
◇ Test scrubRemovesImCalledPattern() started.
◇ Test nilSnippetIsAllowed() started.
◇ Test entryPreservesFields() started.
◇ Test entryHasUniqueID() started.
◇ Test recordAndRetrieve() started.
◇ Test emptyStoreReturnsZeros() started.
◇ Test averageAcrossMultipleEvents() started.
◇ Test scrubRemovesUKPostcodes() started.
◇ Test scrubPreservesNonPIIContent() started.
◇ Test csvExportContainsHeader() started.
◇ Test scrubIsCaseInsensitiveForNames() started.
◇ Test callClampsLevelBelowOne() started.
◇ Test guardrailViolationsSummed() started.
◇ Test roundTripAllTypes() started.
[2026-04-12T05:37:07.181Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=400ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.181Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=401ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.181Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #3, latency=402ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.181Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #4, latency=403ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.181Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #5, latency=404ms, faces=1, rawDataTransmitted=false
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
[2026-04-12T05:37:07.182Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #6, latency=405ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.181Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=44, tokensRedacted=2
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #7, latency=406ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #8, latency=407ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #9, latency=408ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #10, latency=409ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #11, latency=410ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #12, latency=411ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #13, latency=412ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #14, latency=413ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #15, latency=414ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #3, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #16, latency=415ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #17, latency=416ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=44, tokensRedacted=2
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #18, latency=417ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #19, latency=418ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #20, latency=419ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #21, latency=420ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #22, latency=421ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #23, latency=422ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.183Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #24, latency=423ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #25, latency=424ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=100ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=200ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #3, latency=300ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #26, latency=425ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #27, latency=426ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=500ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=500ms, faces=3, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #28, latency=427ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #3, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #29, latency=428ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #30, latency=429ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #31, latency=430ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #32, latency=431ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #33, latency=432ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #34, latency=433ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #35, latency=434ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.185Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #36, latency=435ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.186Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #37, latency=436ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.186Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #38, latency=437ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.186Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #39, latency=438ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.186Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #40, latency=439ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.186Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #41, latency=440ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.184Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.186Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #42, latency=441ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.289Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #43, latency=442ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.289Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #44, latency=443ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.289Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #45, latency=444ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.289Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #46, latency=445ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.290Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #47, latency=446ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.290Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #48, latency=447ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.290Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #49, latency=448ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.290Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #50, latency=449ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.292Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #51, latency=450ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.292Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #52, latency=451ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.292Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #53, latency=452ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.292Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #54, latency=453ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.292Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #55, latency=454ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.292Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #56, latency=455ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.289Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #3, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.292Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=61, tokensRedacted=3
[2026-04-12T05:37:07.293Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=33, tokensRedacted=0
[2026-04-12T05:37:07.293Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=44, tokensRedacted=2
[2026-04-12T05:37:07.293Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=32, tokensRedacted=0
[2026-04-12T05:37:07.293Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=34, tokensRedacted=0
[2026-04-12T05:37:07.293Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-12T05:37:07.292Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #57, latency=456ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.293Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #58, latency=457ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #59, latency=458ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #60, latency=459ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=12, tokensRedacted=1
[2026-04-12T05:37:07.291Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=16, tokensRedacted=1
[2026-04-12T05:37:07.293Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=32, tokensRedacted=0
[2026-04-12T05:37:07.294Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=13, tokensRedacted=1
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #61, latency=460ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=34, tokensRedacted=0
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #62, latency=461ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #63, latency=462ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #64, latency=463ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=29, tokensRedacted=1
[2026-04-12T05:37:07.294Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=18, tokensRedacted=1
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #65, latency=464ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #66, latency=465ms, faces=2, rawDataTransmitted=false
◇ Test customBeatReturnedFromStart() started.
◇ Test throwsOnModelUnavailable() started.
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=500ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #67, latency=466ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.294Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=500ms, faces=0, rawDataTransmitted=false
◇ Test startStoryActivatesSession() started.
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #68, latency=467ms, faces=1, rawDataTransmitted=false
◇ Test endSessionResetsState() started.
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #69, latency=468ms, faces=2, rawDataTransmitted=false
◇ Test throwsOnModelDownloading() started.
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #70, latency=469ms, faces=0, rawDataTransmitted=false
◇ Test throwsOnNoActiveSession() started.
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #71, latency=470ms, faces=1, rawDataTransmitted=false
◇ Test continueTurnIncrementsTurnCount() started.
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #72, latency=471ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #73, latency=472ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #74, latency=473ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #75, latency=474ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #76, latency=475ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #77, latency=476ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #78, latency=477ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #79, latency=478ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #80, latency=479ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #81, latency=480ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #82, latency=481ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #83, latency=482ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #84, latency=483ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=22, tokensRedacted=1
[2026-04-12T05:37:07.295Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #85, latency=484ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #86, latency=485ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #87, latency=486ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=18, tokensRedacted=1
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #88, latency=487ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #89, latency=488ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #90, latency=489ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.295Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=14, tokensRedacted=1
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #91, latency=490ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=34, tokensRedacted=0
◇ Test callReturnsNonEmptyString() started.
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #92, latency=491ms, faces=1, rawDataTransmitted=false
◇ Test callReturnsNewSettingInOutput() started.
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #93, latency=492ms, faces=2, rawDataTransmitted=false
◇ Test callDoesNotMutatePersistentState() started.
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #94, latency=493ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #95, latency=494ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=0, tokensRedacted=0
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #96, latency=495ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #97, latency=496ms, faces=0, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #98, latency=497ms, faces=1, rawDataTransmitted=false
[2026-04-12T05:37:07.296Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=16, tokensRedacted=1
[2026-04-12T05:37:07.296Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #99, latency=498ms, faces=2, rawDataTransmitted=false
[2026-04-12T05:37:07.297Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #100, latency=499ms, faces=0, rawDataTransmitted=false
✔ Test synthesisFailed_hasDescription() passed after 0.129 seconds.
[2026-04-12T05:37:07.297Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=16, tokensRedacted=1
✔ Test synthesisFailed_isLocalizedError() passed after 0.129 seconds.
✔ Test onboardingFilterExcludesMFiCamera() passed after 0.129 seconds.
✔ Test allCasesHaveDescriptions() passed after 0.129 seconds.
✔ Test bluetoothRequirementIsCorrect() passed after 0.129 seconds.
✔ Test multipleCallsAccumulateBookmarks() passed after 0.129 seconds.
✔ Test allCasesCount() passed after 0.129 seconds.
✔ Test callReturnsConfirmationString() passed after 0.129 seconds.
✔ Test modelUnavailableHasDescription() passed after 0.128 seconds.
✔ Test generationFailedIncludesDetail() passed after 0.129 seconds.
✔ Test resultContainsBothPayloadAndMetrics() passed after 0.130 seconds.
✔ Test callAddsBookmarkToStore() passed after 0.129 seconds.
✔ Test metricsAreCodable() passed after 0.129 seconds.
✔ Test rawDataTransmittedAlwaysFalse() passed after 0.129 seconds.
✔ Test payloadContainsNoBoundingBoxes() passed after 0.129 seconds.
✔ Test facesBlurredEqualsFacesDetected() passed after 0.129 seconds.
✔ Test payloadContainsNoBase64() passed after 0.129 seconds.
✔ Test safeFallbackIsNotEnding() passed after 0.128 seconds.
✔ Test endingFallbackMarkedAsEnding() passed after 0.129 seconds.
✔ Test payloadContainsNoDataFields() passed after 0.129 seconds.
✔ Test manualConstructionPreservesFields() passed after 0.129 seconds.
✔ Test safeFallbackHasNonEmptyFields() passed after 0.129 seconds.
✔ Test payloadContainsOnlyAllowedKeys() passed after 0.128 seconds.
✔ Test pitchMultiplierIsWithinValidRange() passed after 0.128 seconds.
✔ Test speechRateMultiplierSlowsDownSpeech() passed after 0.128 seconds.
✔ Test pitchMultiplierIsAboveNeutral() passed after 0.128 seconds.
✔ Test sendableConformance() passed after 0.129 seconds.
✔ Test codableRoundTrip() passed after 0.128 seconds.
✔ Test volumeIsWithinValidRange() passed after 0.128 seconds.
✔ Test activeStates() passed after 0.128 seconds.
✔ Test addAndRetrieve() passed after 0.128 seconds.
✔ Test errorEquality() passed after 0.128 seconds.
✔ Test headerParsing() passed after 0.129 seconds.
✔ Test descriptionsAreNonEmpty() passed after 0.128 seconds.
✔ Test caseIterableContainsAllThreeModes() passed after 0.128 seconds.
✔ Test connectedStates() passed after 0.128 seconds.
✔ Test rawValueRoundTrip() passed after 0.128 seconds.
✔ Test displayNamesAreNonEmpty() passed after 0.128 seconds.
✔ Test sendableConformance() passed after 0.128 seconds.
✔ Test invalidRawValueReturnsNil() passed after 0.128 seconds.
✔ Test speakRecordsTextsInOrder() passed after 0.128 seconds.
✔ Test generateAndEncodeReturnsConfiguredData() passed after 0.128 seconds.
✔ Test speakEmptyStringIsRecorded() passed after 0.128 seconds.
✔ Test storyBeatSpeaksTextThenQuestion() passed after 0.128 seconds.
✔ Test speakRecordsCallCount() passed after 0.128 seconds.
✔ Test speechRateIsWithinValidRange() passed after 0.128 seconds.
✔ Test resetClearsAllEvents() passed after 0.128 seconds.
✔ Test recordAndRetrieve() passed after 0.127 seconds.
✔ Test piiScrubberAndSpeechServiceShareSameLogic() passed after 0.130 seconds.
✔ Test eventCount() passed after 0.128 seconds.
✔ Test averageLatencyEmptyStore() passed after 0.127 seconds.
✔ Test totalTokensScrubbed() passed after 0.128 seconds.
✔ Test rawValues() passed after 0.128 seconds.
✔ Test totalFacesDetectedAndBlurred() passed after 0.127 seconds.
✔ Test averageLatency() passed after 0.127 seconds.
✔ Test sanitisationRateEmptyStore() passed after 0.127 seconds.
✔ Test csvExportEmptyStore() passed after 0.127 seconds.
✔ Test generateAndEncodeThrowsWhenConfigured() passed after 0.127 seconds.
✔ Test sendableConformance() passed after 0.127 seconds.
✔ Test constructionFromScenePayload() passed after 0.127 seconds.
✔ Test directInitialiserPreservesFields() passed after 0.127 seconds.
✔ Test termsAndOnboardingFlagsRoundTrip() passed after 0.130 seconds.
✔ Test nilTranscriptPreserved() passed after 0.127 seconds.
✔ Test speakEmptyStringReturnsImmediately() passed after 0.127 seconds.
✔ Test nilTranscriptEncodes() passed after 0.127 seconds.
✔ Test scenePayloadNeverContainsRawImageData() passed after 0.128 seconds.
✔ Test sanitisationRateIs100Percent() passed after 0.128 seconds.
✔ Test scrubHandlesMultiplePIITypes() passed after 0.127 seconds.
✔ Test scrubCountsRedactedTokens() passed after 0.127 seconds.
✔ Test scrubRemovesUSZipCodes() passed after 0.126 seconds.
✔ Test scrubRemovesNamePatterns() passed after 0.127 seconds.
✔ Test scrubPreservesStoryVocabulary() passed after 0.127 seconds.
✔ Test scrubRemovesEmailAddresses() passed after 0.122 seconds.
✔ Test scrubRemovesStreetAddresses() passed after 0.126 seconds.
✔ Test scrubRemovesLongNumbers() passed after 0.122 seconds.
✔ Test csvExportContainsHeaderAndRows() passed after 0.128 seconds.
✔ Test encodesCorrectly() passed after 0.128 seconds.
✔ Test scrubRemovesPhoneNumbers() passed after 0.122 seconds.
✔ Test constructionWithEmptyArrays() passed after 0.122 seconds.
✔ Test recordAndRetrieve() passed after 0.122 seconds.
✔ Test emptyStoreReturnsZeros() passed after 0.122 seconds.
✔ Test averageAcrossMultipleEvents() passed after 0.122 seconds.
✔ Test scrubRemovesUKPostcodes() passed after 0.122 seconds.
✔ Test scrubPreservesNonPIIContent() passed after 0.122 seconds.
✔ Test scrubRemovesImCalledPattern() passed after 0.122 seconds.
✔ Test csvExportContainsHeader() passed after 0.122 seconds.
✔ Test scrubHandlesEmptyString() passed after 0.122 seconds.
✔ Test guardrailViolationsSummed() passed after 0.122 seconds.
✔ Test scrubIsCaseInsensitiveForNames() passed after 0.122 seconds.
✔ Test hundredRunsNeverTransmitRawData() passed after 0.132 seconds.
✔ Test callClampsLevelBelowOne() passed after 0.122 seconds.
✔ Test callReturnsNonEmptyString() passed after 0.004 seconds.
✔ Test callReturnsNewSettingInOutput() passed after 0.004 seconds.
✔ Suite AudioErrorTests passed after 0.135 seconds.
✔ Suite StoryErrorTests passed after 0.135 seconds.
✔ Suite BookmarkMomentToolTests passed after 0.135 seconds.
✔ Test callDoesNotMutatePersistentState() passed after 0.005 seconds.
✔ Suite PipelineResultTests passed after 0.136 seconds.
✔ Suite PrivacyMetricsInvariantTests passed after 0.137 seconds.
✔ Suite ScenePayloadPrivacyTests passed after 0.136 seconds.
✔ Suite StoryBeatTests passed after 0.136 seconds.
✔ Suite StoryMetricsEventTests passed after 0.136 seconds.
✔ Suite StoryGenerationModeTests passed after 0.136 seconds.
✔ Suite MockAudioServiceTests passed after 0.136 seconds.
✔ Suite PrivacyMetricsStoreTests passed after 0.136 seconds.
✔ Suite PrivacyComplianceTests passed after 0.137 seconds.
✔ Suite SceneContextTests passed after 0.136 seconds.
✔ Suite UserDefaultsOnboardingTests passed after 0.136 seconds.
✔ Suite ScenePayloadTests passed after 0.136 seconds.
✔ Suite PIIScrubberTests passed after 0.136 seconds.
✔ Suite StoryMetricsStoreTests passed after 0.137 seconds.
✔ Suite SwitchSceneToolTests passed after 0.137 seconds.
◇ Test clearRemovesAll() started.
◇ Test callClampsLevelAboveThree() started.
✔ Test clearRemovesAll() passed after 0.001 seconds.
◇ Test bookmarkHasTimestamp() started.
✔ Test bookmarkHasTimestamp() passed after 0.001 seconds.
✔ Suite StoryBookmarkStoreTests passed after 0.146 seconds.
✔ Test roundTripAllTypes() passed after 0.133 seconds.
◇ Test unknownRawValueFallsBackToDefault() started.
✔ Test unknownRawValueFallsBackToDefault() passed after 0.001 seconds.
✔ Suite UserDefaultsWearableTypeTests passed after 0.148 seconds.
✔ Test callClampsLevelAboveThree() passed after 0.012 seconds.
◇ Test callPersistsValidLevel() started.
✔ Test callPersistsValidLevel() passed after 0.102 seconds.
◇ Test callReturnsNonEmptyString() started.
✔ Test callReturnsNonEmptyString() passed after 0.001 seconds.
✔ Suite AdjustDifficultyToolTests passed after 0.255 seconds.
◇ Suite StoryDifficultyLevelTests started.
◇ Test defaultLevelIsTwo() started.
✔ Test defaultLevelIsTwo() passed after 0.001 seconds.
◇ Test roundTripValidValues() started.
✔ Test roundTripValidValues() passed after 0.005 seconds.
◇ Test clampsBelowOne() started.
✔ Test clampsBelowOne() passed after 0.001 seconds.
◇ Test clampsAboveThree() started.
✔ Test voiceLanguageResolvesToNonNilVoice() passed after 0.260 seconds.
✔ Suite AudioServiceVoiceSettingsTests passed after 0.264 seconds.
void * _Nullable NSMapGet(NSMapTable * _Nonnull, const void * _Nullable): map table argument is NULL
✔ Test clampsAboveThree() passed after 0.094 seconds.
✔ Suite StoryDifficultyLevelTests passed after 0.102 seconds.
✔ Suite DifficultyLevelTests passed after 0.358 seconds.
Unknown client: SeeSaw
✔ Test scanningDisplayTitleIsGeneric() passed after 0.847 seconds.
✔ Test roundTrip() passed after 0.848 seconds.
✔ Test rejectsTooShortPacket() passed after 0.848 seconds.
✔ Suite TransferChunkTests passed after 0.852 seconds.
✔ Suite SessionStateTests passed after 0.851 seconds.
✔ Test nilSnippetIsAllowed() passed after 0.919 seconds.
✔ Test entryPreservesFields() passed after 0.919 seconds.
✔ Test customBeatReturnedFromStart() passed after 0.973 seconds.
✔ Test throwsOnModelUnavailable() passed after 0.973 seconds.
✔ Test endSessionResetsState() passed after 0.973 seconds.
✔ Test startStoryActivatesSession() passed after 0.973 seconds.
✔ Test continueTurnIncrementsTurnCount() passed after 0.973 seconds.
✔ Test throwsOnModelDownloading() passed after 0.973 seconds.
✔ Test throwsOnNoActiveSession() passed after 0.974 seconds.
✔ Suite MockStoryServiceLifecycleTests passed after 1.103 seconds.
✔ Test presetTopicsAreUnique() passed after 1.478 seconds.
✔ Test presetTopicsAreNonEmpty() passed after 1.478 seconds.
✔ Suite ChildProfileTests passed after 1.482 seconds.
✔ Test entryHasUniqueID() passed after 1.470 seconds.
✔ Suite TimelineEntryTests passed after 1.482 seconds.
[2026-04-12T05:37:09.020Z] [DEBUG] [AudioService.speak:169] AudioService: speaking, chars=2
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
✔ Test inOrderReassembly() passed after 2.068 seconds.
✔ Test resetClearsBuffer() passed after 2.068 seconds.
✔ Suite ChunkBufferTests passed after 2.071 seconds.
[2026-04-12T05:37:09.577Z] [DEBUG] [AudioService.speak:183] AudioService: speech done, chars=2
✔ Test allTypesHaveNonEmptyDisplayProperties() passed after 2.410 seconds.
✔ Test speakWhitespaceDoesNotCrash() passed after 2.406 seconds.
✔ Suite WearableTypeTests passed after 2.413 seconds.
✔ Suite AudioServiceEmptyTextTests passed after 2.412 seconds.
✔ Test run with 125 tests in 32 suites passed after 2.414 seconds.