import Foundation

struct KnowledgeAnswerComposer: Sendable {
  private let maximumSentenceCount: Int
  private let maximumCharacterCount: Int

  init(
    maximumSentenceCount: Int = 4,
    maximumCharacterCount: Int = 600
  ) {
    self.maximumSentenceCount = max(1, maximumSentenceCount)
    self.maximumCharacterCount = max(80, maximumCharacterCount)
  }

  func compose(
    record: ArtistKnowledgeRecord,
    identity: MusicIdentity
  ) throws -> KnowledgeAnswer {
    var sentences: [String] = []

    if let biography = normalized(record.biography) {
      sentences.append(contentsOf: splitIntoSentences(biography))
    }
    for fact in record.facts.compactMap(normalized) {
      sentences.append(contentsOf: splitIntoSentences(fact))
    }

    let uniqueSentences = sentences.reduce(into: [String]()) { result, sentence in
      guard !result.contains(sentence) else { return }
      result.append(sentence)
    }
    guard !uniqueSentences.isEmpty else {
      throw MusicKnowledgeError.noData
    }

    let spokenText = boundedText(from: uniqueSentences)
    guard !spokenText.isEmpty else {
      throw MusicKnowledgeError.noData
    }

    return KnowledgeAnswer(
      scope: .artist,
      identity: identity,
      spokenText: spokenText,
      source: .musicNerdAPI
    )
  }

  private func splitIntoSentences(_ value: String) -> [String] {
    var sentences: [String] = []
    value.enumerateSubstrings(
      in: value.startIndex..<value.endIndex,
      options: [.bySentences, .substringNotRequired]
    ) { _, range, _, _ in
      let sentence = value[range].trimmingCharacters(in: .whitespacesAndNewlines)
      if !sentence.isEmpty {
        sentences.append(sentence)
      }
    }
    return sentences.isEmpty ? [value] : sentences
  }

  private func boundedText(from sentences: [String]) -> String {
    var accepted: [String] = []

    for sentence in sentences.prefix(maximumSentenceCount) {
      let candidate = (accepted + [sentence]).joined(separator: " ")
      guard candidate.count <= maximumCharacterCount else { break }
      accepted.append(sentence)
    }

    if !accepted.isEmpty {
      return accepted.joined(separator: " ")
    }

    let firstSentence = sentences[0]
    guard firstSentence.count > maximumCharacterCount else {
      return firstSentence
    }

    let allowedPrefix = firstSentence.prefix(maximumCharacterCount - 1)
    let words = allowedPrefix.split(separator: " ")
    let truncated = words.dropLast().joined(separator: " ")
    let safePrefix = truncated.isEmpty ? String(allowedPrefix) : truncated
    return safePrefix + "…"
  }

  private func normalized(_ value: String?) -> String? {
    guard let value else { return nil }
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return normalized.isEmpty ? nil : normalized
  }
}
