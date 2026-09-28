import SwiftUI

struct SquareImageCropper: View {
    let image: UIImage
    var onCancel: () -> Void
    var onCrop: (UIImage) -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 300

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Move and scale")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 40)

                Spacer()

                ZStack {
                    Color.gray.opacity(0.3)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cropSize, height: cropSize)
                        .scaleEffect(scale)
                        .offset(offset)
                }
                .frame(width: cropSize, height: cropSize)
                .clipShape(Rectangle())
                .contentShape(Rectangle())
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(1.0, lastScale * value)
                            }
                            .onEnded { _ in
                                lastScale = scale
                            },
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                )
                .overlay {
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                }

                Spacer()

                HStack(spacing: 40) {
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.system(size: 16, weight: .medium))
                    }

                    Button {
                        let cropped = renderCroppedImage()
                        onCrop(cropped)
                    } label: {
                        Text("Done")
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func renderCroppedImage() -> UIImage {
        let renderer = ImageRenderer(content:
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cropSize, height: cropSize)
                    .scaleEffect(scale)
                    .offset(offset)
            }
            .frame(width: cropSize, height: cropSize)
            .clipped()
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? image
    }
}
