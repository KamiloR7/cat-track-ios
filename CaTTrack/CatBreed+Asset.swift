//
//  CatBreed+Asset.swift
//  CaTTrack
//
//  Maps each CatBreed to the name of its default image asset in
//  Assets.xcassets. The mapping is explicit so display names
//  (rawValue) and asset names can evolve independently — and so
//  there is exactly one place to look when an image stops loading.
//
//  All assets should be 300×300 (square crop centered on the cat's
//  face) so they render cleanly inside a circular frame.
//

import Foundation

extension CatBreed {
    
    /// Asset catalog name for the breed's default image.
    /// If the asset is missing, PetAvatarView will fall back to
    /// "cat_default" and ultimately to an SF Symbol.
    var assetName: String {
        switch self {
        case .domesticShorthair: return "cat_domestic_shorthair"
        case .domesticLonghair:  return "cat_domestic_longhair"
        case .siamese:           return "cat_siamese"
        case .persian:           return "cat_persian"
        case .maineCoon:         return "cat_maine_coon"
        case .ragdoll:           return "cat_ragdoll"
        case .bengal:            return "cat_bengal"
        case .britishShorthair:  return "cat_british_shorthair"
        case .sphynx:            return "cat_sphynx"
        case .scottishFold:      return "cat_scottish_fold"
        case .russianBlue:       return "cat_russian_blue"
        case .abyssinian:        return "cat_abyssinian"
        case .americanShorthair: return "cat_american_shorthair"
        case .norwegianForest:   return "cat_norwegian_forest"
        case .other:             return "cat_default"
        }
    }
}
