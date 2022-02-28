//
//  EmojiArtModel.swift
//  EmojiArt
//

import Foundation


struct EmojiArtModel {
    var background = Background.blank
    var emojis = [Emoji]()
 
    init() { }
    
    struct Emoji: Identifiable, Hashable {
        let text: String
        var x: Int // offset from the center
        var y: Int // offset from the center
        var size: Int
        let id: Int
        var selected: Bool
        
        fileprivate init(text: String,
             x: Int,
             y: Int,
             size: Int,
             id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
            self.selected = false
        }
    }
    
    mutating func selectedEmoji(emoji: EmojiArtModel.Emoji){
        if let currentEmoji = emojis.firstIndex(where: {$0.id == emoji.id}){
            emojis[currentEmoji].selected.toggle()
        }
        
    }
    
    mutating func deselectAllEmojis(emoji: EmojiArtModel.Emoji){
        
    }
    
    mutating func deleteEmojisOnDoc(_ emoji: Emoji) {
        emojis.removeAll()
    }
    
    mutating func moveOnlySelectedEmoji(emoji: EmojiArtModel.Emoji){
        
        if let allSelectedEmojis =  emojis.firstIndex(where: {$0.id == emoji.id}){
            emojis[allSelectedEmojis].selected.toggle()
        }
        
    }
    
    
    private(set) var uniqueEmojiId = 0

    mutating func addEmoji(_ emoji: String,
                           at location: (x: Int, y: Int),
                           size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: emoji,
                            x: location.x,
                            y: location.y,
                            size: size,
                            id: uniqueEmojiId))
    }
    
}
