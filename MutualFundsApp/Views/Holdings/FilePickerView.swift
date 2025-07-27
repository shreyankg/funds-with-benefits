import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: UIViewControllerRepresentable {
    let onFileSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [UTType.pdf, UTType.commaSeparatedText],
            asCopy: true
        )
        
        documentPicker.delegate = context.coordinator
        documentPicker.allowsMultipleSelection = false
        documentPicker.modalPresentationStyle = .formSheet
        
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePickerView
        
        init(_ parent: FilePickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onFileSelected(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if needed
        }
    }
}

struct FileUploadInstructionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Upload Holdings File")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Supported file formats:")
                    .font(.headline)
                
                InstructionRow(
                    icon: "doc.fill",
                    title: "PDF Files",
                    description: "Holdings statements from brokers like Groww, Zerodha, etc."
                )
                
                InstructionRow(
                    icon: "tablecells.fill",
                    title: "CSV Files",
                    description: "Comma-separated values with holdings data"
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Required columns for CSV:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Scheme Name, AMC, Category, Sub Category, Folio Number, Source, Units, Invested Value, Current Value, Returns, XIRR")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text("The app will automatically match your holdings with our fund database for detailed analysis.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    FileUploadInstructionsView()
}