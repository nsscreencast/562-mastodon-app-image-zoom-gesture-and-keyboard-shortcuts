import AppKit
import SwiftUI
import Manfred

final class GalleryWindowManager {
    static let shared = GalleryWindowManager()

    private var windowController: GalleryWindowController?

    func show(media: [MediaAttachment], selectedIndex: Int, sourceRect: NSRect, placeholderImage: Image?) {
        windowController?.close()

        windowController = GalleryWindowController(
            media: media,
            selectedIndex: selectedIndex,
            sourceRect: sourceRect,
            placeholderImage: placeholderImage
        )
        windowController?.showWindow(self)
    }
}

private final class GalleryWindowController: NSWindowController {
    convenience init(media: [MediaAttachment], selectedIndex: Int, sourceRect: NSRect, placeholderImage: Image?) {
        let panel = NSPanel(
            contentRect: sourceRect,
            styleMask: [.hudWindow, .utilityWindow, .closable, .resizable, .titled],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(
            rootView:
                GalleryRoot(media: media, selectedIndex: selectedIndex, placeholderImage: placeholderImage)
                .frame(minWidth: sourceRect.width, maxWidth: .infinity, minHeight: sourceRect.height, maxHeight: .infinity)
        )
        self.init(window: panel)
    }

    override func showWindow(_ sender: Any?) {
        guard let window else { return }

        window.makeKeyAndOrderFront(self)

        let targetSize = CGSize(width: 800, height: 600)
        let targetOrigin = CGPoint(
            x: window.frame.midX - targetSize.width/2,
            y: window.frame.midY - targetSize.height/2
        )
        let largerFrame = CGRect(origin: targetOrigin, size: targetSize)
        NSAnimationContext.runAnimationGroup { context in
            context.timingFunction = .init(name: .easeInEaseOut)
            window.animator().setFrame(largerFrame, display: true)
        }
    }
}

private struct GalleryRoot: View {
    let media: [MediaAttachment]
    let selectedIndex: Int
    let placeholderImage: Image?

    var body: some View {
        ZoomingView {
            imageItem(imageURL: media[selectedIndex].url)
        }
    }

    private func imageItem(imageURL: URL) -> some View {
        RemoteImageView(url: imageURL) { image in
            image.resizable()
        } placeholder: {
            if let placeholderImage {
                placeholderImage.resizable()
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .aspectRatio(contentMode: .fit)
        .frame(minWidth: 200, minHeight: 200)
    }
}

struct ZoomingView<T: View>: NSViewRepresentable {
    @ViewBuilder let content: () -> T

    func makeNSView(context: Context) -> _ZoomingView {
        _ZoomingView(contentView: NSHostingView(rootView: content()))
    }

    func updateNSView(_ zoomingNSView: _ZoomingView, context: Context) {
    }
}

final class _ZoomingView: NSView {
    let contentView: NSView
    let scrollView: NSScrollView

    init(contentView: NSView) {
        self.contentView = contentView
        scrollView = NSScrollView()
        super.init(frame: .zero)

        scrollView.frame = bounds
        scrollView.autoresizingMask = [.width, .height]
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 1
        scrollView.maxMagnification = 10
        scrollView.backgroundColor = .black

        contentView.frame = bounds
        contentView.autoresizingMask = [.width, .height]

        addSubview(scrollView)
        scrollView.documentView = contentView
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        window?.makeFirstResponder(self)
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        let zoomStep: CGFloat = 1
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "=" {
            changeZoom(delta: zoomStep)
        } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "-" {
            changeZoom(delta: -zoomStep)
        } else {
            super.keyDown(with: event)
        }
    }

    private func changeZoom(delta: CGFloat) {
        scrollView.animator().magnification += delta
    }
}
