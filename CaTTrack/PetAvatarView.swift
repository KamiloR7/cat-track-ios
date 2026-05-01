//
//  PetAvatarView.swift
//  CaTTrack
//
//  Reusable circular cat avatar. Used on the dashboard cat profile
//  card and anywhere else a pet's image is displayed.
//
//  Fallback chain (graceful degradation):
//    1. Breed-specific image  (e.g. "cat_siamese")
//    2. Generic "cat_default" image
//    3. SF Symbol "cat.fill" on an orange background
//
//  This means the component never renders nothing — even if no
//  assets ship, the SF Symbol fallback matches the original
//  dashboard look.
//

import SwiftUI

struct PetAvatarView: View {
    
    let breed: CatBreed?
    let size: CGFloat
    
    init(breed: CatBreed?, size: CGFloat = 60) {
        self.breed = breed
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background tint always present — the 60pt orange disc.
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: size, height: size)
            
            avatarContent
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }
    
    // MARK: - Fallback chain
    
    @ViewBuilder
    private var avatarContent: some View {
        if let breed, hasImageAsset(named: breed.assetName) {
            // Tier 1: the exact breed image.
            Image(breed.assetName)
                .resizable()
                .scaledToFill()
        } else if hasImageAsset(named: "cat_default") {
            // Tier 2: the generic default.
            Image("cat_default")
                .resizable()
                .scaledToFill()
        } else {
            // Tier 3: SF Symbol — matches the original dashboard look
            // before any assets are added.
            Image(systemName: "cat.fill")
                .resizable()
                .scaledToFit()
                .padding(size * 0.2)
                .foregroundStyle(.orange)
        }
    }
    
    /// Returns true if Assets.xcassets contains an image set with
    /// the given name. Uses UIImage(named:) which returns nil when
    /// the asset is missing — cheap to call (UIKit caches lookups).
    private func hasImageAsset(named name: String) -> Bool {
        UIImage(named: name) != nil
    }
}

#Preview("Avatar fallback chain", traits: .sizeThatFitsLayout) {
    HStack(spacing: 16) {
        PetAvatarView(breed: .siamese, size: 60)
        PetAvatarView(breed: .maineCoon, size: 60)
        PetAvatarView(breed: nil, size: 60)
    }
    .padding()
}
