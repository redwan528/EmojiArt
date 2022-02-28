//
//  EmojiArtDocumentView.swift
//  EmojiArt
//

import SwiftUI

struct EmojiArtDocumentView: View {
    
    @ObservedObject var document: EmojiArtDocument

    
    // MARK: - body
    
    var body: some View {
        VStack {
            documentBody
            palette
        }
    }
    
    // MARK: - documentBody
    @State private var allSelectedEmojis = Set<EmojiArtModel.Emoji>()
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                        .onTapGesture {
                            //supposed to deselect all emojis when clicking background, will get back to this
                            allSelectedEmojis.removeAll()
                            
                        }
                )
                .gesture(doubleTapToZoom(in: geometry.size))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView()
                        .scaleEffect(3)
                }
                ForEach(document.emojis) { emoji in
                    Text(emoji.text)
                        .font(.system(size: fontSize(for: emoji)))
                        .scaleEffect(zoomScale)
                        .border((emoji.selected) ? Color.red: Color.clear)
                        .background((emoji.selected) ? Color.white: Color.clear).opacity(10)
                        .position(position(for: emoji, in: geometry))
                        
             .onTapGesture { //allows to drag emojis on the canvas
                withAnimation{
                   // document.deleteEmojisOnDoc(emoji)
                    document.selectEmoji(emoji: emoji)
                   // allSelectedEmojis()
                    
                }
                        }
                   // if emoji.selected {
                        .onDrag { NSItemProvider(object: emoji.text as NSString)}
                    //}
                    
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                    Button ("Delete all Emojis", action: {
                        document.deleteEmojisOnDoc(emoji)

                    })
                    }
                    }
                }
              
            }
            
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
            
             .onTapGesture {
                //deselectAllEmojisWithOneTouch()
            }
        }
    }
    
    
 

    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    //4:37am
    private func deselectAllEmojisWithOneTouch () -> some Gesture {
        
        TapGesture()
            .onEnded{
               // let deselectAll = document.selectEmoji(emoji: testEmojis)
               // document.selectEmoji(emoji: EmojiArtModel.Emoji)
                allSelectedEmojis.removeAll()
               
        }
    }
    
    //private func onlyMoveSelectedEmoji() -> some Gesture {
      //  ForEach(document.emojis){ emoji in//
       //     if emojis[currentEmoji]
       //     Text(emoji.text)
        //        .onTapGesture {
         //           document.selectEmoji(emoji: emoji)
           // if let currentEmoji = emojis.firstIndex(where: {$0.id == emoji.id}){
               //if emojis[currentEmoji].selected.toggle()
       //     }
     //   }
   // }
    
    private func position(for emoji: EmojiArtModel.Emoji,
                          in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func drop(providers: [NSItemProvider],
                      at location: CGPoint,
                      in geometry: GeometryProxy) -> Bool {
        
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(.url(url.imageURL))
        }

        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(String(emoji),
                                      at: convertToEmojiCoordinates(location,
                                                                    in: geometry),
                                      size: defaultEmojiFontSize / zoomScale)
                }
            }
        }
        
        return found
    }

    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int),
                                            in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    
 
    
    private func convertToEmojiCoordinates(_ location: CGPoint,
                                           in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return(Int(location.x), Int(location.y))
    }

    @State private var steadyStateZoomScale: CGFloat = 1
   
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    
    @State private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalGestureValue in
                steadyStatePanOffset = steadyStatePanOffset +
                    (finalGestureValue.translation / zoomScale)
            }
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }

    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image,
           image.size.width > 0, image.size.height > 0,
           size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
        
    }

    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
        }
    }
    
    
    
    
    // MARK: - palette
    let defaultEmojiFontSize: CGFloat = 60

    var palette : some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    // MARK: - testEmojis

    let testEmojis = "☎️📞⌚️🎥⏰🕰🪓🔪🔧🔨🛢🔮🌡🪑🏮🛎📔📒📪📫🛏📌📎❤️💛💙🔺🔸🔶▪️🇵🇷🇱🇧🏴󠁧󠁢󠁥󠁮󠁧󠁿🇹🇷🇩🇴🇨🇺⥤➽⬅︎☜$⨜∑ℇ⊆⊇"


// MARK: - ScrollingEmojisView

struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) },
                        id: \.self ) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
 
