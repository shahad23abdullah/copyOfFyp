import SwiftUI

struct ContentView: View {
    @State private var progress: Double = 0.0
    @State private var message: String = ""
    
    let serverURL = URL(string: "http://192.168.100.15:8888/check")! // Replace with your server URL
    
    var body: some View {
        VStack {
            ProgressView(value: progress, total: 100.0)
                .padding()
            
            Button(action: checkMessage) {
                Text("Check")
            }
            .padding()
            
            Text(message)
                .padding()
        }
    }
    
    func checkMessage() {
        guard let url = URL(string: "http://192.168.100.15:8888/check") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let responseString = String(data: data, encoding: .utf8), let number = Double(responseString) {
                    DispatchQueue.main.async {
                        self.message = responseString
                        self.progress = number // Update progress to the received number
                    }
                }
            } else {
                print("Failed to receive message")
            }
        }
        task.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
_______________________________________________________________________________________________
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var progress: Double = 0.0
    @State private var message: String = ""
    @State private var audioFileName: String = ""
    @State private var serverResponse: String = ""

    @StateObject private var viewModel = AudioViewModel()
    @State private var isShowingPicker = false
    @State private var selectedFileURL: URL?

    let serverURL = URL(string: "http://192.168.100.15:8888/check")! // Replace with your server URL

    var body: some View {
        VStack {
            ProgressView(value: progress, total: 100.0)
                .padding()

            TextField("Enter Audio Name", text: $audioFileName)
                .padding()

            Button("Check & Upload Audio") {
                checkAndUpload()
            }
            .padding()

            Text(viewModel.statusMessage)
                .padding()

            Text(serverResponse)
                .padding()
        }
    }

    func checkAndUpload() {
        if let fileURL = selectedFileURL {
            uploadFileToServer(filePath: fileURL, fileName: audioFileName) { success, response in
                if success {
                    viewModel.setStatusMessage("Audio uploaded successfully")
                    serverResponse = response ?? ""
                    // Clear the text field after sending the audio
                    audioFileName = ""
                } else {
                    viewModel.setStatusMessage("Failed to upload audio")
                }
            }
        } else {
            viewModel.setStatusMessage("Please select an audio file first")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AudioPicker: UIViewControllerRepresentable {
    var onAudioSelected: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onAudioSelected: onAudioSelected)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onAudioSelected: (URL) -> Void

        init(onAudioSelected: @escaping (URL) -> Void) {
            self.onAudioSelected = onAudioSelected
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onAudioSelected(url)
            }
        }
    }
}

class AudioViewModel: ObservableObject {
    @Published var statusMessage: String = ""

    func setStatusMessage(_ message: String) {
        DispatchQueue.main.async {
            self.statusMessage = message
        }
    }
}

func uploadFileToServer(filePath: URL, fileName: String, completion: @escaping (Bool, String?) -> Void) {
    guard let fileData = try? Data(contentsOf: filePath) else {
        print("Failed to read file data.")
        completion(false, nil)
        return
    }

    let url = URL(string: "http://192.168.100.4:8888/upload-audio")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!) // Convert string to data
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!) // Convert string to data
    body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!) // Convert string to data
    body.append(fileData) // Append binary data directly
    body.append("\r\n".data(using: .utf8)!) // Convert string to data
    body.append("--\(boundary)--\r\n".data(using: .utf8)!) // Convert string to data

    request.httpBody = body

    let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
        if let error = error {
            print("Error uploading file: \(error)")
            completion(false, nil)
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            if (200..<300).contains(httpResponse.statusCode) {
                print("File uploaded successfully.")
                if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                    completion(true, responseString)
                } else {
                    completion(true, nil)
                }
            } else {
                print("Server returned error: \(httpResponse.statusCode)")
                completion(false, nil)
            }
        }
    }

    task.resume()
}
_______________________________________________________________________________________
ABAN CODE 
_______________________________________________________________________________________
*ABAN*import SwiftUI
import UniformTypeIdentifiers
import Foundation

class AudioViewModel: ObservableObject {
    @Published var statusMessage: String = ""

    func setStatusMessage(_ message: String) {
        DispatchQueue.main.async {
            self.statusMessage = message
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AudioViewModel()
    @State private var isShowingPicker = false
    @State private var selectedFileURL: URL?
    @State private var audioFileName: String = ""
    @State private var serverResponse: String = ""
    @State private var progress : CGFloat = 0.0

    var body: some View {
        VStack {
            Spacer()
            
            Text("ABAN AI detection")
                .font(.title)
                .padding(.top , -80)
            
            CirculeProgressBar(progress: progress)
                .frame(width: 200 , height: 200)
                .padding(.bottom, 10 )
        
            Button("check") {
                if let fileURL = selectedFileURL {
                    uploadFileToServer(filePath: fileURL, fileName: audioFileName) { success, response in
                        if success {
                            viewModel.setStatusMessage("Audio uploaded successfully")
                            checkMessage()
                            serverResponse = response ?? ""
                            audioFileName = ""
                            
                        } else {
                            viewModel.setStatusMessage("Failed to upload audio")
                        }
                    }
                } else {
                    viewModel.setStatusMessage("Please select an audio file first")
                }
            }
            .padding()
            .font(.headline)
            .background(.mint)
            .cornerRadius(50)
            .foregroundColor(.white)
            .padding(.bottom , 10 )
            
            HStack{
                ZStack(alignment: .trailing){
                    TextField("Audio Name", text: $audioFileName)
                        .padding(.vertical,10)
                        .padding(.horizontal ,20 )
                        .background(Color.lightGray)
                        .cornerRadius(50)
                        .foregroundColor(Color.DarkGray)

                    Button("Upload") {
                        isShowingPicker = true
                        progress = 0.0
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical,15)
                    .padding(.horizontal)
                    .background(.mint)
                    .cornerRadius(60)
                    .sheet(isPresented: $isShowingPicker) {
                        AudioPicker { url in
                            selectedFileURL = url
                            audioFileName = url.lastPathComponent
                        }
                    }
                }
            }
            .padding(.horizontal , 10)
            
            Spacer()
        }
        .padding(.top, -40)
    }
    func checkMessage() {
        guard let url = URL(string: "http://192.168.100.11:8888/check") else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let responseString = String(data: data, encoding: .utf8), let number = Double(responseString) {
                    DispatchQueue.main.async {
                        let number = number/100
                        self.progress = number 
                    }
                }
            } else {
                print("Failed to receive message")
            }
        }
        task.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AudioPicker: UIViewControllerRepresentable {
    var onAudioSelected: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onAudioSelected: onAudioSelected)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onAudioSelected: (URL) -> Void

        init(onAudioSelected: @escaping (URL) -> Void) {
            self.onAudioSelected = onAudioSelected
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onAudioSelected(url)
            }
        }
    }
}

func uploadFileToServer(filePath: URL, fileName: String, completion: @escaping (Bool, String?) -> Void) {
    guard let fileData = try? Data(contentsOf: filePath) else {
        print("Failed to read file data.")
        completion(false, nil)
        return
    }
    
    let url = URL(string: "http://192.168.100.11:8888/upload-audio")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!) // Convert string to data
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!) // Convert string to data
    body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!) // Convert string to data
    body.append(fileData) // Append binary data directly
    body.append("\r\n".data(using: .utf8)!) // Convert string to data
    body.append("--\(boundary)--\r\n".data(using: .utf8)!) // Convert string to data
    
    request.httpBody = body
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error uploading file: \(error)")
            completion(false, nil)
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            if (200..<300).contains(httpResponse.statusCode) {
                print("File uploaded successfully.")
                if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                    completion(true, responseString)
                } else {
                    completion(true, nil)
                }
            } else {
                print("Server returned error: \(httpResponse.statusCode)")
                completion(false, nil)
            }
        }
    }.resume()
}

struct  CirculeProgressBar : View {
    
    var progress : CGFloat
    
    var body : some View {
        
        ZStack{
            
            //light gray circle " Base cirlce "
            Circle()
                .stroke(lineWidth: 15.0)
                .opacity(0.3)
                .foregroundColor(Color(UIColor.lightGray))
            
            //tiffany cilrcle " progress circle"
            Circle()
                .trim(from: 0.0 , to: progress)
                .stroke(style: StrokeStyle(lineWidth: 18 , lineCap: .round , lineJoin: .round))
                .rotation(Angle (degrees: 270.0))
                .animation(.linear, value: 3 )
                .foregroundColor(.mint)
            
            // text to display the percentage of progress
            Text(String(format: "%0.0f%%", progress*100.0))
                .font(.system(size: 30))
        }
    }
}


extension Color{
    
    static var Tiffany : Color {
        Color(red:0.278 , green:0.847 , blue:0.780 )
    }
    static var lightGray : Color {
        Color(red:0.867 , green:0.867 , blue:0.867 )
    }
    static var DarkGray : Color {
        Color(red:0.6157 , green:0.6157 , blue:0.6157 )
    }
}
_______________________________________________________________________________________________________________
import SwiftUI
import AVFoundation
import UserNotifications

struct ContentView: View {
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var timer: Timer?
    @State private var serverResponse: String = ""
    let serverURL = URL(string: "http://192.168.100.11:5000/upload_sound_data")!

    var body: some View {
        VStack {
            Toggle("Record Sound", isOn: $isRecording)
                .padding()
                .onChange(of: isRecording) { newValue in
                    if newValue {
                        checkMicrophonePermission()
                    } else {
                        stopRecording()
                    }
                }

            Text("Server Response: \(serverResponse)")
                .padding()
        }
        .onAppear {
            requestPermissions()
        }
    }

    func requestPermissions() {
        checkMicrophonePermission()
        requestNotificationPermission()
    }

    func checkMicrophonePermission() {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            print("Microphone permission granted")
            startRecording()
        case .denied:
            print("Microphone permission denied")
        case .undetermined:
            print("Microphone permission undetermined")
            requestMicrophonePermission()
        @unknown default:
            print("Unknown microphone permission status")
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            if success {
                print("Notification authorization granted")
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }

    func requestMicrophonePermission() {
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.requestRecordPermission { granted in
            if granted {
                print("Microphone permission granted after request")
                startRecording()
            } else {
                print("Microphone permission denied after request")
            }
        }
    }

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]

            let audioFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("sound.wav")

            let audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: audioSettings)
            audioRecorder.record()
            self.audioRecorder = audioRecorder

            self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
                self.uploadAudioFile(at: audioFileURL)
            }
        } catch let error {
            print("Error setting up audio recording: \(error)")
        }
    }

    func stopRecording() {
        if let audioRecorder = self.audioRecorder {
            audioRecorder.stop()
            self.audioRecorder = nil
        }
        self.timer?.invalidate()
    }

    func uploadAudioFile(at fileURL: URL) {
        guard let audioRecorder = self.audioRecorder else {
            print("Audio recorder is nil.")
            return
        }

        audioRecorder.stop() // Stop recording before uploading

        uploadFileToServer(filePath: fileURL, fileName: "sound.wav") { success, responseData in
            if success {
                if let data = responseData, let httpResponse = responseData as? HTTPURLResponse {
                    print("Server response status code: \(httpResponse.statusCode)")

                    if (200..<300).contains(httpResponse.statusCode), let responseString = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.serverResponse = responseString // Update server response state
                            self.sendPushNotification(with: responseString) // Send push notification with server response
                        }
                    } else {
                        print("Error: Server did not accept the audio file.")
                    }
                } else {
                    print("Error: Invalid server response.")
                }
            } else {
                print("Error: Failed to upload audio file.")
            }
        }
    }

    func uploadFileToServer(filePath: URL, fileName: String, completion: @escaping (Bool, Data?) -> Void) {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)

        do {
            let fileData = try Data(contentsOf: filePath)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error uploading file: \(error)")
                    completion(false, nil)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Server response status code: \(httpResponse.statusCode)")
                    
                    if (200..<300).contains(httpResponse.statusCode) {
                        print("File uploaded successfully.")
                        completion(true, data)
                    } else {
                        print("Server returned error: \(httpResponse.statusCode)")
                        completion(false, nil)
                    }
                }
            }.resume()
        } catch {
            print("Error reading file data: \(error)")
            completion(false, nil)
        }
    }

    func sendPushNotification(with message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Server Response"
        content.body = message

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "serverResponseNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification request: \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
func uploadFileToServerReal(filePath: URL, fileName: String, completion: @escaping (Bool, Data?) -> Void) {
    // Ensure serverURL is defined or passed as a parameter
    
    guard let serverURL = URL(string: "http://192.168.100.11:5000") else {
        print("Invalid server URL")
        completion(false, nil)
        return
    }
    
    var request = URLRequest(url: serverURL)
    request.httpMethod = "POST"
    
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)

    do {
        let fileData = try Data(contentsOf: filePath)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                // Cleanup code
                completion(false, nil) // Assume failure if we reach this point without successful completion
            }
            
            if let error = error {
                print("Error uploading file: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid server response")
                return
            }
            
            print("Server response status code: \(httpResponse.statusCode)")
            
            if (200..<300).contains(httpResponse.statusCode) {
                print("File uploaded successfully.")
                completion(true, data)
            } else {
                print("Server returned error: \(httpResponse.statusCode)")
            }
        }.resume()
    } catch {
        print("Error reading file data: \(error)")
    }
}
