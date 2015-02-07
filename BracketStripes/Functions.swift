//
//  Functions.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/06.
//
//
/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:

         Helpful macros.

 */

// Clamp _value to range [_lo, _hi]
func CLAMP<T: Comparable>(value: T, lo: T, hi: T) -> T {
    return max(lo, min(hi, value))
}
