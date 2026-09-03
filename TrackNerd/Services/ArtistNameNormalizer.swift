import Foundation

struct ArtistNameNormalizer: Sendable {
  func normalized(_ value: String) -> String {
    let folded = value.folding(
      options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
      locale: Locale(identifier: "en_US_POSIX")
    )
    let components = folded.unicodeScalars.split { scalar in
      !CharacterSet.alphanumerics.contains(scalar)
    }
    var tokens = components.map(String.init).filter { !$0.isEmpty }

    if tokens.first == "the", tokens.count > 1 {
      tokens.removeFirst()
    }

    return tokens.joined(separator: " ")
  }

  func confidence(for requestedName: String, candidateName: String) -> Double {
    let requested = normalized(requestedName)
    let candidate = normalized(candidateName)

    guard !requested.isEmpty, !candidate.isEmpty else { return 0 }
    guard requested != candidate else { return 0.95 }

    let requestedTokens = Set(requested.split(separator: " ").map(String.init))
    let candidateTokens = Set(candidate.split(separator: " ").map(String.init))
    let unionCount = requestedTokens.union(candidateTokens).count
    guard unionCount > 0 else { return 0 }

    let overlap = Double(requestedTokens.intersection(candidateTokens).count)
    return min(0.85, 0.85 * overlap / Double(unionCount))
  }
}
