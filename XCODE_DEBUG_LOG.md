warning: (arm64) /Users/jayampathyicloud.com/Library/Developer/Xcode/DerivedData/SeeSaw-drxzukhunglnfxffaoobjgakabns/Build/Products/Debug-iphoneos/SeeSaw.app/SeeSaw empty dSYM file detected, dSYM was created with an executable with no debug info.
12.11.0 - [GoogleUtilities/AppDelegateSwizzler][I-SWZ001014] App Delegate does not conform to UIApplicationDelegate protocol.
[Firebase/Crashlytics] Version 12.11.0
numANECores: Unknown aneSubType
[2026-04-12T09:05:13.587Z] [DEBUG] [PrivacyPipelineService.init:60] init: objectDetectionModel loaded=true
Failed to send CA Event for app launch measurements for ca_event_type: 0 event_name: com.apple.app_launch_measurement.FirstFramePresentationMetric
Reading from public effective user settings.
void * _Nullable NSMapGet(NSMapTable * _Nonnull, const void * _Nullable): map table argument is NULL
Unknown client: SeeSaw
Failed to send CA Event for app launch measurements for ca_event_type: 1 event_name: com.apple.app_launch_measurement.ExtendedLaunchMetrics
<<<< FigXPCUtilities >>>> signalled err=-17281 at <>:308
<<<< FigCaptureSourceRemote >>>> Fig assert: "err == 0 " at bail (FigCaptureSourceRemote.m:569) - (err=-17281)
[2026-04-12T09:05:35.262Z] [DEBUG] [LocalDeviceAccessory.sendCommand:143] sendCommand: command=CAPTURE
[2026-04-12T09:05:35.983Z] [DEBUG] [LocalDeviceAccessory.photoOutput:284] photoOutput: capturedBytes=45788, exifOrientation=6
[2026-04-12T09:05:35.984Z] [DEBUG] [CompanionViewModel.runDetectionPreview:284] runDetectionPreview: start, jpegBytes=45788
[2026-04-12T09:05:36.085Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:207] runDebugDetection – start: inputSize=(360.0, 480.0), modelLoaded=true
[2026-04-12T09:05:36.086Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(360.0, 480.0)
[2026-04-12T09:05:36.204Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-12T09:05:36.213Z] [DEBUG] [PrivacyPipelineService.parseDetections:307] Stage 3 – object detection (recognized): count=7, items=["window@77%", "sofa@97%", "laptop@95%", "potted_plant@97%", "shelf@72%", "table@81%", "table@84%"]
[2026-04-12T09:05:36.213Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithBoxes:281] Stage 3 – object detection (boxes): count=7, items=["window@77%", "sofa@97%", "laptop@95%", "potted_plant@97%", "shelf@72%", "table@81%", "table@84%"]
[2026-04-12T09:05:36.213Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:227] runDebugDetection – detections: count=7, labels=["window", "sofa", "laptop", "potted_plant", "shelf", "table", "table"]
[2026-04-12T09:05:36.227Z] [DEBUG] [PrivacyPipelineService.runDebugDetection:230] runDebugDetection – done: blurredDataBytes=57354
[2026-04-12T09:05:36.228Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #1, latency=242ms, faces=0, rawDataTransmitted=false
[2026-04-12T09:05:36.228Z] [DEBUG] [CompanionViewModel.runDetectionPreview:313] runDetectionPreview: done, detectionCount=7, blurredBytes=57354
[2026-04-12T09:05:40.047Z] [DEBUG] [CompanionViewModel.runFullPipeline:324] runFullPipeline: start, mode=onDevice, jpegBytes=57354, childAge=10
[2026-04-12T09:05:40.047Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:338] runOnDevicePipeline: start
[2026-04-12T09:05:40.053Z] [DEBUG] [PrivacyPipelineService.process:74] Stage 0 – input: imageSize=(480.0, 360.0), childAge=10
[2026-04-12T09:05:40.053Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:160] Stage 1 – face detection: imageSize=(480.0, 360.0)
[2026-04-12T09:05:40.061Z] [DEBUG] [PrivacyPipelineService.detectAndBlurFaces:166] Stage 2 – face blur: faceCount=0, skipping blur
[2026-04-12T09:05:40.068Z] [DEBUG] [PrivacyPipelineService.parseDetections:307] Stage 3 – object detection (recognized): count=1, items=["potted_plant@92%"]
[2026-04-12T09:05:40.068Z] [DEBUG] [PrivacyPipelineService.detectObjectsWithModel:271] Stage 3 – object detection: labels=["potted_plant"]
[2026-04-12T09:05:40.213Z] [DEBUG] [PrivacyPipelineService.classifyScene:381] Stage 4 – scene classification: labels=[]
[2026-04-12T09:05:40.213Z] [DEBUG] [PrivacyPipelineService.recognizeSpeech:398] Stage 5 – speech recognition: skipped: no audio data provided
[2026-04-12T09:05:40.213Z] [DEBUG] [PrivacyPipelineService.process:141] Pipeline benchmark: faceDetect=4ms blur=3ms yolo=151ms scene=151ms stt=151ms piiScrub=0ms total=162ms
[2026-04-12T09:05:40.214Z] [DEBUG] [PrivacyPipelineService.process:142] Stage 6 – output: objects=["potted_plant"], scene=[], hasTranscript=false
[2026-04-12T09:05:40.215Z] [DEBUG] [PrivacyMetricsStore.record:20] PrivacyMetricsStore: recorded event #2, latency=162ms, faces=0, rawDataTransmitted=false
[2026-04-12T09:05:40.215Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:354] runOnDevicePipeline: privacy done, objects=["potted_plant"]
[2026-04-12T09:05:40.272Z] [DEBUG] [StoryTimelineStore.insert:42] StoryTimeline: session inserted id=616EBF55-E7BF-471F-9930-DC2C617C740A
[2026-04-12T09:05:40.324Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
nw_connection_copy_protocol_metadata_internal_block_invoke [C3] Client called nw_connection_copy_protocol_metadata_internal on unconnected nw_connection
nw_connection_copy_protocol_metadata_internal_block_invoke [C3] Client called nw_connection_copy_protocol_metadata_internal on unconnected nw_connection
nw_connection_copy_protocol_metadata_internal_block_invoke [C3] Client called nw_connection_copy_protocol_metadata_internal on unconnected nw_connection
nw_connection_copy_connected_local_endpoint_block_invoke [C3] Client called nw_connection_copy_connected_local_endpoint on unconnected nw_connection
nw_connection_copy_connected_remote_endpoint_block_invoke [C3] Client called nw_connection_copy_connected_remote_endpoint on unconnected nw_connection
nw_connection_copy_protocol_metadata_internal_block_invoke [C4] Client called nw_connection_copy_protocol_metadata_internal on unconnected nw_connection
nw_connection_copy_protocol_metadata_internal_block_invoke [C4] Client called nw_connection_copy_protocol_metadata_internal on unconnected nw_connection
nw_connection_copy_protocol_metadata_internal_block_invoke [C4] Client called nw_connection_copy_protocol_metadata_internal on unconnected nw_connection
nw_connection_copy_connected_local_endpoint_block_invoke [C4] Client called nw_connection_copy_connected_local_endpoint on unconnected nw_connection
nw_connection_copy_connected_remote_endpoint_block_invoke [C4] Client called nw_connection_copy_connected_remote_endpoint on unconnected nw_connection
nw_protocol_instance_set_output_handler Not calling remove_input_handler on 0x12166b0c0:udp
[2026-04-12T09:05:46.451Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=5, textLen=93, hasQuestion=true, isEnding=false
[2026-04-12T09:05:46.451Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:391] runOnDevicePipeline: story generated in 6179ms, ttft=5351ms
[2026-04-12T09:05:46.452Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:392] beat[0] storyText: Vihas was walking through the garden when he spotted a potted plant he had never seen before.
[2026-04-12T09:05:46.452Z] [DEBUG] [CompanionViewModel.runOnDevicePipeline:393] beat[0] question: What do you think this plant is?
[2026-04-12T09:05:46.734Z] [DEBUG] [AudioService.speak:170] AudioService: speaking, chars=93
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
          IPCAUClient.cpp:139   IPCAUClient: can't connect to server (-66748)
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T09:05:52.640Z] [DEBUG] [AudioService.speak:184] AudioService: speech done, chars=93
[2026-04-12T09:05:52.640Z] [DEBUG] [AudioService.speak:170] AudioService: speaking, chars=32
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T09:05:54.472Z] [DEBUG] [AudioService.speak:184] AudioService: speech done, chars=32
[2026-04-12T09:05:55.102Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-12T09:05:55.111Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-12T09:06:01.138Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=4, tokensRedacted=0
[2026-04-12T09:06:01.321Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=7, tokensRedacted=0
[2026-04-12T09:06:02.016Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=9, tokensRedacted=0
[2026-04-12T09:06:02.723Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=15, tokensRedacted=0
[2026-04-12T09:06:04.408Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=15, tokensRedacted=0
[2026-04-12T09:06:05.906Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=2, tokensRedacted=0
[2026-04-12T09:06:06.111Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=6, tokensRedacted=0
[2026-04-12T09:06:06.513Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=14, tokensRedacted=0
[2026-04-12T09:06:08.319Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=19, tokensRedacted=0
[2026-04-12T09:06:08.519Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=27, tokensRedacted=0
[2026-04-12T09:06:08.707Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=28, tokensRedacted=0
[2026-04-12T09:06:10.107Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=28, tokensRedacted=0
[2026-04-12T09:06:10.610Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=2937600
[2026-04-12T09:06:10.610Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=Smell like
[2026-04-12T09:06:10.610Z] [DEBUG] [CompanionViewModel.listenForAnswer:547] listenForAnswer: answer='It has flowers white flowers', length=28
[2026-04-12T09:06:10.713Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
[2026-04-12T09:06:13.301Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=4, textLen=66, hasQuestion=true, isEnding=false
[2026-04-12T09:06:13.301Z] [DEBUG] [CompanionViewModel.continueStoryLoop:471] beat[0] storyText: Vihas walked over to the potted plant and touched its soft leaves.
[2026-04-12T09:06:13.301Z] [DEBUG] [CompanionViewModel.continueStoryLoop:472] beat[0] question: Do you think the plant is happy?
[2026-04-12T09:06:13.377Z] [DEBUG] [AudioService.speak:170] AudioService: speaking, chars=66
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T09:06:16.968Z] [DEBUG] [AudioService.speak:184] AudioService: speech done, chars=66
[2026-04-12T09:06:16.969Z] [DEBUG] [AudioService.speak:170] AudioService: speaking, chars=32
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T09:06:18.789Z] [DEBUG] [AudioService.speak:184] AudioService: speech done, chars=32
[2026-04-12T09:06:19.418Z] [DEBUG] [AudioCaptureService.startCapture:69] startCapture: recording started, sampleRate=48000.0, channels=1
[2026-04-12T09:06:19.420Z] [DEBUG] [SpeechRecognitionService.startLiveTranscription:90] startLiveTranscription: started
[2026-04-12T09:06:22.229Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=3, tokensRedacted=0
[2026-04-12T09:06:22.729Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=5, tokensRedacted=0
[2026-04-12T09:06:23.026Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=10, tokensRedacted=0
[2026-04-12T09:06:23.229Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=16, tokensRedacted=0
[2026-04-12T09:06:23.626Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=21, tokensRedacted=0
[2026-04-12T09:06:24.228Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=23, tokensRedacted=0
[2026-04-12T09:06:24.838Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=29, tokensRedacted=0
[2026-04-12T09:06:25.129Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=33, tokensRedacted=0
[2026-04-12T09:06:25.433Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=39, tokensRedacted=0
[2026-04-12T09:06:25.634Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=43, tokensRedacted=0
[2026-04-12T09:06:25.641Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=45, tokensRedacted=0
[2026-04-12T09:06:26.027Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=50, tokensRedacted=0
[2026-04-12T09:06:26.327Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=55, tokensRedacted=0
[2026-04-12T09:06:26.830Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=60, tokensRedacted=0
[2026-04-12T09:06:27.029Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=66, tokensRedacted=0
[2026-04-12T09:06:27.229Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=69, tokensRedacted=0
[2026-04-12T09:06:27.530Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=75, tokensRedacted=0
[2026-04-12T09:06:27.829Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=78, tokensRedacted=0
[2026-04-12T09:06:28.031Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=83, tokensRedacted=0
[2026-04-12T09:06:29.629Z] [DEBUG] [PIIScrubber.scrub:31] scrub: inputLength=83, tokensRedacted=0
[2026-04-12T09:06:35.363Z] [DEBUG] [AudioCaptureService.stopCapture:90] stopCapture: recording stopped, accumulatedBytes=3014400
[2026-04-12T09:06:35.364Z] [DEBUG] [SpeechRecognitionService.stopTranscription:98] stopTranscription: transcript=
[2026-04-12T09:06:35.364Z] [DEBUG] [CompanionViewModel.listenForAnswer:547] listenForAnswer: answer='Yes I feel happy when I touch the plant and I also feel that plant is happy as well', length=83
[2026-04-12T09:06:35.385Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:231] streamWithErrorRecovery: starting stream
[2026-04-12T09:06:39.397Z] [DEBUG] [OnDeviceStoryService.streamWithErrorRecovery:243] streamWithErrorRecovery: done, snapshots=5, textLen=60, hasQuestion=true, isEnding=true
[2026-04-12T09:06:39.397Z] [DEBUG] [CompanionViewModel.continueStoryLoop:471] beat[1] storyText: Vihas smiled and said, 'I think plants can feel happy too!'.
[2026-04-12T09:06:39.397Z] [DEBUG] [CompanionViewModel.continueStoryLoop:472] beat[1] question: Do you think there are other plants in the garden that are happy too?
[2026-04-12T09:06:39.487Z] [DEBUG] [AudioService.speak:170] AudioService: speaking, chars=60
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T09:06:43.214Z] [DEBUG] [AudioService.speak:184] AudioService: speech done, chars=60
[2026-04-12T09:06:43.215Z] [DEBUG] [AudioService.speak:170] AudioService: speaking, chars=69
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
         AVAudioBuffer.mm:281   mBuffers[0].mDataByteSize (0) should be non-zero
[2026-04-12T09:06:46.559Z] [DEBUG] [AudioService.speak:184] AudioService: speech done, chars=69
[2026-04-12T09:06:46.561Z] [DEBUG] [StoryTimelineStore.finalizeSession:50] StoryTimeline: session finalised beats=3, restart=false
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
TimeDataFormattingStorage was resolved without idiom! - SwiftUICore/Logging.swift:84 - please file a bug report.
[2026-04-12T09:09:16.989Z] [DEBUG] [StoryTimelineStore.delete:85] StoryTimeline: session deleted id=616EBF55-E7BF-471F-9930-DC2C617C740A