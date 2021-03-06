//
//  FuzzyAdaptation.swift
//  StevesFuzzyAdaptation
//
//  Created by Steve Trombley on 7/14/17.
//  Copyright © 2017 Steve Trombley. All rights reserved.
//

import Foundation

public struct FuzzyMatchOptions {
    // defines how strict you want to be when fuzzy matching. A value of 0.0 is equivalent to an exact match. A value of 1.0 indicates a very loose understanding of whether a match has been found.
    var threshold:Double = FuzzyMatchingOptionsDefaultValues.threshold.rawValue
    // defines where in the host String to look for the pattern
    var distance:Double = FuzzyMatchingOptionsDefaultValues.distance.rawValue
}

public enum FuzzyMatchingOptionsDefaultValues : Double {
    // Default threshold value. Defines how strict you want to be when fuzzy matching. A value of 0.0 is equivalent to an exact match. A value of 1.0 indicates a very loose understanding of whether a match has been found.
    case threshold = 0.5
    // Default distance value. Defines where in the host String to look for the pattern.
    case distance = 1000.0
}

@objc public class fuzzying: NSObject {

    @objc public override init() {
        
    }

    
    @objc public func getFuzzyMatchResultWithSample(_ sampleText: String, pattern: String, location: Int, threshold: Double, distance: Double) -> Int {
        let options = FuzzyMatchOptions(threshold: threshold, distance: distance)
        let result = sampleText.fuzzyMatchPattern(pattern, loc:location, options:options)
        return result!
    }
    
    
 
}

/**
 Allows for fuzzy matching to happen on all String elements in an Array.
 */
extension Sequence where Iterator.Element == String {
    
    /**
     Iterates over all elements in the array and executes a fuzzy match using the `pattern` parameter.
     
     - parameter pattern: The pattern to search for.
     - parameter loc: defines the approximate position in the text where the pattern is expected to be found.
     - parameter distance: Determines how close the match must be to the fuzzy location. See `loc` parameter.
     - returns: An ordered set of Strings based on whichever element matches closest to the `pattern` parameter.
     */
    public func sortedByFuzzyMatchPattern(_ pattern:String, loc:Int? = 0, distance:Double? = FuzzyMatchingOptionsDefaultValues.distance.rawValue) -> [String] {
        var indexesAdded = [Int]()
        var sortedArray = [String]()
        for element in stride(from: 1, to: 10, by: 1) {
            // stop if we've already found all there is to find
            if sortedArray.count == underestimatedCount { break }
            // otherwise, proceed to the rest of the values
            var options = FuzzyMatchOptions.init(threshold:Double(Double(element) / Double(10)), distance:FuzzyMatchingOptionsDefaultValues.distance.rawValue)
            if let unwrappedDistance = distance {
                options.distance = unwrappedDistance
            }
            for (index, value) in self.enumerated() {
                if !indexesAdded.contains(index) {
                    if let _ = value.fuzzyMatchPattern(pattern, loc: loc, options: options) {
                        sortedArray.append(value)
                        indexesAdded.append(index)
                    }
                }
            }
        }
        // make sure that the array we return to the user has ALL elements which is in the initial array
        for (index, value) in self.enumerated() {
            if !indexesAdded.contains(index) {
                sortedArray.append(value)
            }
        }
        return sortedArray
    }
}

/**
 Allows for fuzzy matching to happen on Strings
 */
extension String {
    
    /**
     Provides a confidence score relating to how likely the pattern is to be found in the host string.
     
     - parameter pattern: The pattern to search for.
     - parameter loc: The index in the element from which to search.
     - parameter distance: Determines how close the match must be to the fuzzy location. See `loc` parameter.
     - returns: A Double which indicates how confident we are that the pattern can be found in the host string. A low value (0.001) indicates that the pattern is likely to be found. A high value (0.999) indicates that the pattern is not likely to be found
     */
    public func confidenceScore(_ pattern:String, loc:Int? = 0, distance:Double? = FuzzyMatchingOptionsDefaultValues.distance.rawValue) -> Double? {
        // start at a low threshold and work our way up
        for index in stride(from: 1, to: 1000, by: 1) {
            let threshold:Double = Double(Double(index) / Double(1000))
            var d = FuzzyMatchingOptionsDefaultValues.distance.rawValue
            if let unwrappedDistance = distance {
                d = unwrappedDistance
            }
            let options = FuzzyMatchOptions.init(threshold: threshold, distance: d)
            if self.fuzzyMatchPattern(pattern, loc: loc, options: options) != nil {
                return threshold
            }
        }
        return nil
    }
    
    /**
     Executes a fuzzy match on the String using the `pattern` parameter.
     
     - parameter pattern: The pattern to search for.
     - parameter loc: The index in the element from which to search.
     - parameter options: Dictates how the search is executed. See `FuzzyMatchingOptionsParams` and `FuzzyMatchingOptionsDefaultValues` for details.
     - returns: An Int indicating where the fuzzy matched pattern can be found in the String.
     */
    public func fuzzyMatchPattern(_ pattern:String, loc:Int? = 0, options:FuzzyMatchOptions? = nil) -> Int? {
        guard characters.count > 0 else { return nil }
        let generatedOptions = generateOptions(options)
        let location = max(0, min(loc ?? 0, characters.count))
        let threshold = generatedOptions.threshold
        let distance = generatedOptions.distance
        
        if caseInsensitiveCompare(pattern) == ComparisonResult.orderedSame {
            return 0
        } else if pattern.isEmpty {
            return nil
        } else {
            if (location + pattern.characters.count) < characters.count {
                let substring = self[self.characters.index(self.startIndex, offsetBy: 0)...self.characters.index(self.startIndex, offsetBy: pattern.characters.count)]
                if pattern.caseInsensitiveCompare(String(substring)) == ComparisonResult.orderedSame {
                    return location
                } else {
                    return matchBitapOfText(pattern, loc:location, threshold:threshold, distance:distance)
                }
            } else {
                return matchBitapOfText(pattern, loc:location, threshold:threshold, distance:distance)
            }
        }
    }
    
    func matchBitapOfText(_ pattern:String, loc:Int, threshold:Double, distance:Double) -> Int? {
        let alphabet = matchAlphabet(pattern)
        let bestGuessAtThresholdAndLocation = speedUpBySearchingForSubstring(pattern, loc:loc, threshold:threshold, distance:distance)
        var scoreThreshold = bestGuessAtThresholdAndLocation.threshold
        var bestLoc = bestGuessAtThresholdAndLocation.bestLoc
        
        let matchMask = 1 << (pattern.characters.count - 1)
        var binMin:Int
        var binMid:Int
        var binMax = pattern.characters.count + characters.count
        var rd:[Int?] = [Int?]()
        var lastRd:[Int?] = [Int?]()
        bestLoc = NSNotFound
        for (index, _) in pattern.characters.enumerated() {
            binMin = 0
            binMid = binMax
            while binMin < binMid {
                let score = bitapScoreForErrorCount(index, x:(loc + binMid), loc:loc, pattern:pattern, distance:distance)
                if score <= scoreThreshold {
                    binMin = binMid
                } else {
                    binMax = binMid
                }
                binMid = (binMax - binMin) / 2 + binMin
            }
            binMax = binMid
            var start = maxOfConstAndDiff(1, b:loc, c:binMid)
            let finish = min(loc + binMid, characters.count) + pattern.characters.count
            rd = [Int?](repeating: 0, count: finish + 2)
            rd[finish + 1] = (1 << index) - 1
            var j = finish
            for _ in stride(from: j, to: start - 1, by: -1) {
                var charMatch:Int
                if characters.count <= j - 1 {
                    charMatch = 0
                } else {
                    let character = String(self[characters.index(startIndex, offsetBy: j - 1)])
                    if characters.count <= j - 1 || alphabet[character] == nil {
                        charMatch = 0
                    } else {
                        charMatch = alphabet[character]!
                    }
                }
                if index == 0 {
                    rd[j] = ((rd[j + 1]! << 1) | 1) & charMatch
                } else {
                    rd[j] = (((rd[j + 1]! << 1) | 1) & charMatch) | (((lastRd[j + 1]! | lastRd[j]!) << 1) | 1) | lastRd[j + 1]!
                }
                if (rd[j]! & matchMask) != 0 {
                    let score = bitapScoreForErrorCount(index, x:(j - 1), loc:loc, pattern:pattern, distance:distance)
                    if score <= scoreThreshold {
                        scoreThreshold = score
                        bestLoc = j - 1
                        if bestLoc > loc {
                            start = maxOfConstAndDiff(1, b:2 * loc, c:bestLoc)
                        } else {
                            break
                        }
                    }
                }
                j = j - 1
            }
            if bitapScoreForErrorCount(index + 1, x:loc, loc:loc, pattern:pattern, distance:distance) > scoreThreshold {
                break
            }
            lastRd = rd
        }
        return bestLoc != NSNotFound ? bestLoc : nil
    }
    
    func matchAlphabet(_ pattern:String) -> [String: Int] {
        var alphabet = [String: Int]()
        for char in pattern.characters {
            alphabet[String(char)] = 0
        }
        for (i, char) in pattern.characters.enumerated() {
            let stringRepresentationOfCharacter = String(char)
            let possibleEntry = alphabet[stringRepresentationOfCharacter]!
            let value = possibleEntry | (1 << (pattern.characters.count - i - 1))
            alphabet[stringRepresentationOfCharacter] = value
        }
        return alphabet
    }
    
    func bitapScoreForErrorCount(_ e:Int, x:Int, loc:Int, pattern:String, distance:Double) -> Double {
        let accuracy:Double = Double(e) / Double(pattern.characters.count)
        let proximity = abs(loc - x)
        if distance == 0 {
            return Double(proximity == 0 ? accuracy : 1)
        } else {
            return Double(Double(accuracy) + (Double(proximity) / distance))
        }
    }
    
    func speedUpBySearchingForSubstring(_ pattern:String, loc:Int, threshold:Double, distance:Double) -> (bestLoc: Int, threshold: Double) {
        var scoreThreshold = threshold
        var bestLoc = NSNotFound
        var range: Range<String.Index> = startIndex..<characters.index(startIndex, offsetBy: characters.count)
        if let possibleLiteralSearchRange = self.range(of: pattern, options:NSString.CompareOptions.literal, range:range, locale: Locale.current) {
            bestLoc = characters.distance(from: startIndex, to: possibleLiteralSearchRange.lowerBound)
            scoreThreshold = min(bitapScoreForErrorCount(0, x:bestLoc, loc:loc, pattern:pattern, distance:distance), threshold)
            range = startIndex..<characters.index(startIndex, offsetBy: min(loc + pattern.characters.count, characters.count))
            if let possibleBackwardsSearchRange = self.range(of: pattern, options:NSString.CompareOptions.backwards, range:range, locale: Locale.current) {
                bestLoc = characters.distance(from: startIndex, to: possibleBackwardsSearchRange.lowerBound)
                scoreThreshold = min(bitapScoreForErrorCount(0, x:bestLoc, loc:loc, pattern:pattern, distance:distance), scoreThreshold)
            }
        }
        return (bestLoc, threshold)
    }
    
    func generateOptions(_ options:FuzzyMatchOptions?) -> FuzzyMatchOptions {
        if let unwrappedOptions = options {
            return unwrappedOptions
        } else {
            return FuzzyMatchOptions.init()
        }
    }
    
    func maxOfConstAndDiff(_ a:Int, b:Int, c:Int) -> Int {
        return b <= c ? a : b - c + a
    }
}
