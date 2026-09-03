# Music Nerd iOS 27 App Intents, Apple Intelligence, and Siri Prototype Handoff

**Status:** Phase 2 technical feasibility demonstrated; primary Siri product gate failed because reliable invocation requires an app-specific learned phrase

**Prepared:** August 30, 2026; updated September 2, 2026

**Audience:** iOS developer or coding agent

**Prototype host:** Existing MusicNerd app target, on a dedicated branch with a debug-only spike surface

**Target:** Preserve the app's current iOS 18.2 minimum. The illustrative production intents are availability-gated to iOS 26+ for `supportedModes`; the Audio App Schema and App Intents Testing work targets iOS 27

> Important: `MusicAuthorization`, `SystemMusicPlayer`, `queue.currentEntry`, custom `AppIntent`, and `AppShortcut` are not iOS 27-only APIs. The Audio App Schema types used here, execution-target controls, and App Intents Testing contain the relevant iOS 27-specific surface. Use Xcode 27's generated schema templates as the source of truth for beta protocol requirements and names, and retest those layers on each SDK seed.

## 1. Executive decision

The prototype proves that Music Nerd can safely read current Apple Music playback, resolve the artist, and return grounded knowledge through an App Intent. It does **not** establish a viable primary Siri product experience: reliable invocation currently requires users to learn an app-specific trigger phrase, which the product owner has rejected as a non-starter.

Do not advance the custom App Shortcut route as the primary V1 entry point or begin Phase 3 under that assumption. Preserve the working prototype as technical evidence until the team explicitly chooses whether to retain it as an optional Shortcuts, Action Button, or automation surface.

The prototype was correctly built inside the existing MusicNerd app target rather than a standalone app or second Xcode project. The dedicated feature branch, debug-only diagnostic screen, and read-only playback resolver preserved the production bundle ID, signing, MusicKit authorization, App Shortcut identity, and lifecycle behavior needed for a valid result.

A separate app is justified only if the team has a firm policy against opening or building the shipping project with beta Xcode. Even then, results from the separate bundle are provisional and must be repeated in MusicNerd before proceeding.

### Target scenario

1. Apple Music is playing a song.
2. The user invokes Siri.
3. The user asks Music Nerd for context about the current song or artist.
4. Music Nerd identifies the current Apple Music item, queries its knowledge service, and returns a concise spoken answer without mutating Apple Music's queue or transport state.

Siri may temporarily duck or pause audible playback while listening or speaking. “Playback remains unchanged” in this document means Music Nerd does not replace the queue, play, pause, seek, skip, or otherwise mutate transport state; it does not promise acoustically uninterrupted Siri audio.

### Prototype trigger phrases — not recommended as primary product UX

- “Siri, ask Music Nerd about this song.”
- “Siri, ask Music Nerd about this artist.”
- “Siri, tell me about this song using Music Nerd.”

The custom App Shortcut mechanism requires app-named trigger templates. Flexible matching can recognize nearby wording, but it does not remove the product burden of discovering and remembering how to address this custom action. Physical-device testing confirmed the concern: the distinctive registered phrase worked, while the natural “Ask Music Nerd about...” wording fell back to opening the app.

### Do not promise this V1 utterance

- “Siri, tell me about this artist.”

Music Nerd cannot currently register itself as the generic preferred provider for music knowledge. There is no documented App Schema for an action such as `explainSong`, `explainArtist`, or `answerMusicQuestion`, and there is no public API equivalent to “always use Music Nerd for informational questions about music.”

### Technical route tested

The prototype first proved current-item visibility with a debug-only diagnostic, then implemented the artist App Intent in the same app target and exposed it as an App Shortcut. Do not add the song intent unless a viable no-incantation product entry point is found. The tested implementation reads the current Apple Music queue item using:

```swift
SystemMusicPlayer.shared.queue.currentEntry
```

Resolve the queue entry into a stable Music Nerd song/artist identity, call a shared knowledge service, and return a short `ProvidesDialog` result. The resolver must only read playback state; it must not replace the queue, call `play()`, pause, seek, or otherwise mutate playback.

Do not add this responsibility to the existing `AppleMusicService`, which owns preview and playback behavior. Introduce a separately auditable `CurrentPlaybackResolving` implementation with no mutating player methods in its interface.

### Secondary research route

iOS 27 lets media apps associate schematized entities with their own Now Playing metadata, and lets compatible entities move between apps through `Transferable` and `IntentValueRepresentation`. This is directionally promising, but Apple does not currently document a contract guaranteeing that Apple Music's current `.audio.song` or `.audio.artist` entity will be passed into an arbitrary third-party Music Nerd knowledge intent. Do not make this cross-app transfer path a V1 dependency.

## 2. Product goal

Make Music Nerd an “audio commentary layer” over Apple Music:

```text
Apple Music playback
        |
        v
Current song / artist identity
        |
        v
Explicit Siri invocation of Music Nerd
        |
        v
Music Nerd knowledge and recommendation services
        |
        v
Short spoken answer, with optional visual snippet or app deep link
```

The initial product value is contextual music knowledge without forcing the user to leave playback, search manually, or make Music Nerd the audio player.

Example answer categories:

- artist overview and scene
- song and album context
- release history
- writing, performance, and production credits
- influences and connections
- why a recording matters
- suggested related listening

### Feasibility-spike success criteria

- A debug-only surface in the existing MusicNerd app reads and displays a snapshot of `SystemMusicPlayer.shared.queue.currentEntry`.
- The spike runs under MusicNerd's real bundle ID, signing, existing App ID with the MusicKit App Service enabled, and authorization state.
- Results are recorded on at least two physical devices for catalog songs, music videos, radio/autoplay, local or matched content, and transient entries.
- Queue identity, playback status, and playback position are compared before and after each read.
- Music Nerd performs no playback mutation.
- No backend, App Intents, Spotlight, App Entities, Foundation Models, or conversational work begins until this gate passes.

### Production V1 success criteria

- The approved explicit, app-named Siri phrases reliably invoke Music Nerd on supported devices.
- The current Apple Music song is correctly identified in at least 95% of an agreed test catalog.
- Music Nerd does not change Apple Music's queue or transport state throughout the interaction.
- The first spoken response begins within a product-defined latency budget; target 2–4 seconds for cached facts and 5–8 seconds for a network-generated answer.
- Failure states are short, specific, and actionable.
- No answer is produced when identity confidence is too low.

### V1 non-goals

- Becoming Siri's default music knowledge provider.
- Replacing Apple Music playback or queue management.
- Supporting every audio app's Now Playing item.
- Guaranteeing unqualified conversational follow-ups such as “Who produced it?” without naming Music Nerd again.
- Indexing Music Nerd's entire global catalog into Spotlight.
- Using Foundation Models as a substitute for a grounded music knowledge source.
- Building rich song-specific explanations before Music Nerd has a canonical recording identity and song-level knowledge source. The current artist-oriented service may support the artist intent first; the song intent may use a deterministic stub or explicitly limited answer during the prototype.

## 3. What the iOS 27 pieces provide

The architecture spans several OS generations. The current-playback feasibility gate uses MusicKit APIs available since iOS 15, and custom App Intents/App Shortcuts are available from iOS 16. Preserve MusicNerd's iOS 18.2 deployment target. The sample production intent types deliberately require iOS 26 for `supportedModes`; the Audio App Schema types, execution-target controls, and testing features used later require iOS 27.

| Technology | What it provides | Music Nerd use | What it does **not** provide |
|---|---|---|---|
| `AppIntent` | A typed action available to system surfaces such as Shortcuts, Spotlight, widgets, controls, and App Shortcuts | `ExplainCurrentSongIntent` and `ExplainCurrentArtistIntent` | Automatic promotion of every custom action into a Siri AI tool |
| App Schemas | Apple-defined semantic contracts for known entities, enums, and actions | Describe Music Nerd songs and artists using `.audio.song` and `.audio.artist`; adopt matching audio actions only if Music Nerd actually performs them | A custom “music knowledge provider” role or an `explainSong` schema |
| `AppEntity` | A lightweight, system-facing representation of app data | Stable Music Nerd song and artist identities, display data, deep-link routing, intent parameters/results | A replacement for the domain or persistence model |
| `IndexedEntity` | Makes an entity eligible for donation to Spotlight's lexical and semantic index | Make selected Music Nerd artists/songs and useful properties findable and available to Apple Intelligence | Automatic indexing of the backend or unlimited semantic Q&A |
| Spotlight / Core Spotlight | Local semantic retrieval and system discovery for donated content | Index saved, viewed, favorited, downloaded, or otherwise locally relevant Music Nerd content | A server-wide search layer; use app queries/backend search when the corpus is too large or volatile |
| View annotations and `NSUserActivity` | Associates visible app UI with App Entities so Siri can resolve “this,” “that,” or a visible list item | Annotate Music Nerd's own artist, song, album, and credit views | Permission to annotate another app's UI |
| Now Playing entity annotations | Lets the app publishing Now Playing metadata associate one or more entity identifiers with that media | Useful if Music Nerd later publishes its own Now Playing experience | A way for Music Nerd to alter Apple Music's Now Playing metadata |
| `Transferable` | Describes serializable representations of an entity for transfer between processes/apps | Support safe entity export/import and test round trips | Guaranteed semantic interoperability merely because a JSON/file representation exists |
| `IntentValueRepresentation` | Bridges an App Entity to a compatible system intent value, such as an `IntentPerson` or `PlaceDescriptor` | Adopt only if the shipping SDK exposes a suitable media value for the data being transferred | A generic adapter that makes any song entity acceptable to every audio intent |
| Interaction donations | Tells the system about real, completed, schema-backed actions performed in the app UI | Donate eligible Music Nerd UI actions to improve relevance and app preference signals | A supported method for forcing Siri to choose Music Nerd as the answer provider |
| `AppIntentsTesting` | Out-of-process integration tests through the real App Intents infrastructure | Test intent execution, definitions, queries, entity transfer, Spotlight indexing, and annotations | A substitute for end-to-end Siri language/runtime testing or real MusicKit playback tests |

## 4. Foundation Models and App Intents are different layers

This section is architectural context, not Phase 0 work. The first vertical slice does not need Foundation Models: use a deterministic diagnostic during feasibility and the existing grounded artist data for the first production answer. Revisit generated composition only after current-item resolution, identity, and latency are proven.

These frameworks solve complementary problems.

### Foundation Models

Foundation Models lets **Music Nerd call a language model**. Use it inside the app for tasks such as:

- converting grounded Music Nerd facts into a concise spoken answer
- summarizing long biographies or liner-note material
- classifying a question into artist/song/album/credit scope
- generating structured output from known source material

```text
Music Nerd -> Foundation Models / another model provider -> generated output
```

### App Intents

App Intents lets **system experiences call into Music Nerd's actions and data**.

```text
Siri / Shortcuts / Spotlight
            |
            v
   App Intents and App Entities
            |
            v
   Music Nerd domain services
```

An intent may call a Music Nerd service that internally uses Foundation Models, but Foundation Models does not register the app as a Siri provider. Likewise, adding App Intents does not automatically give Music Nerd an in-app generative model.

### Grounding rule

Any generated answer must be grounded in Music Nerd's licensed/catalog data. The model may organize and phrase facts; it must not invent biographies, credits, release dates, or relationships. Prefer structured facts plus source identifiers, and keep a non-generative template fallback.

## 5. The key Siri routing limitation

This routing work begins only after the current-playback feasibility gate passes.

There are two distinct App Intents lanes:

1. **Ordinary custom App Intents.** These can appear across system surfaces and can be exposed through App Shortcuts. They remain useful for optional explicit actions, but the prototype rejected them as Music Nerd's primary V1 Siri mechanism.
2. **Schema-backed intents.** These conform to Apple-defined actions that Siri already understands, such as the Audio domain's `playAudio`, `addToLibrary`, `addToPlaylist`, `createStation`, `recognizeAudio`, and `updateAudioAffinity` schemas.

Apple's documented Audio action vocabulary is about playback, recognition, libraries, playlists, stations, and affinity. It does not currently contain a generic music-explanation or music-Q&A schema.

Therefore:

```text
“Tell me about this artist”
        X
No public rule says Siri must select Music Nerd.

“Explain the current artist with Music Nerd”
        |
        v
Music Nerd App Shortcut / custom App Intent
```

### Product implication

Treat the custom App Shortcut lane as a technical capability, not the primary Siri UX. Do not compensate for unreliable natural routing by teaching users an incantation in onboarding or settings.

A schema-backed action is the only current route intended to give Siri system-defined semantics without app-specific trigger templates. Apple does not currently provide an `explainArtist`, `explainSong`, or music-knowledge schema. The iOS 27 `.system.searchInApp` schema is worth a separate, tightly scoped investigation only if opening Music Nerd to its own search-results UI is acceptable; it is not equivalent to returning a hands-free current-artist answer in Siri.

## 6. Runtime architecture

### Phase 0 diagnostic architecture

Keep the feasibility spike deliberately smaller than the production design:

```text
MusicNerd debug-only diagnostic screen
        |
        v
CurrentPlaybackResolving
        |
        +--> MusicAuthorization
        +--> SystemMusicPlayer.shared.queue.currentEntry
        |
        v
Ephemeral on-screen snapshot and manual test record
```

Phase 0 performs no identity matching, backend calls, App Intent execution, SwiftData persistence, answer composition, or analytics. Keep the diagnostic out of release builds.

### Contingent production V1 architecture

```text
Siri / App Shortcut
        |
        v
ExplainCurrentSongIntent or ExplainCurrentArtistIntent
        |  thin adapter
        v
CurrentPlaybackResolving
        |
        +--> MusicAuthorization
        +--> SystemMusicPlayer.shared.queue.currentEntry
        |
        v
PlaybackIdentityResolver
        |
        +--> Apple Music catalog ID
        +--> Music Nerd canonical ID crosswalk
        +--> metadata fallback with confidence score
        |
        v
MusicKnowledgeService
        |
        +--> short-lived in-memory cache
        +--> Music Nerd API / graph
        +--> optional grounded response composer
        |
        v
IntentDialog + optional snippet/deep link/entity result
```

### Keep intent types thin

Intent code should validate invocation state, call one domain service, and convert the domain result into an intent result. It should not contain MusicKit parsing, catalog matching, HTTP logic, prompt construction, or persistence code.

Suggested shared modules/protocols:

```swift
protocol CurrentPlaybackResolving: Sendable {
    func currentItem() async throws -> CurrentPlaybackItem
}

protocol MusicIdentityResolving: Sendable {
    func resolve(_ item: CurrentPlaybackItem) async throws -> MusicIdentity
}

protocol MusicKnowledgeServing: Sendable {
    func overview(for identity: MusicIdentity, scope: KnowledgeScope) async throws -> KnowledgeAnswer
    func answer(_ question: String, context: MusicConversationContext) async throws -> KnowledgeAnswer
}
```

Prefer dependency injection (`@Dependency` where appropriate) so the UI, App Intents, unit tests, and App Intents integration tests can reuse the same services.

Phase 0 needs only `CurrentPlaybackItem` and `CurrentPlaybackResolving`. Add identity and knowledge protocols after the feasibility gate passes. If production intents use App Intents' `@Dependency`, register their dependencies with `AppDependencyManager` or provide an explicit bridge to MusicNerd's existing service container; the property wrapper does not automatically resolve that container.

## 7. Current Apple Music item resolution

### Authorization

MusicKit requires user authorization before other MusicKit APIs are used.

1. Verify and update the existing `NSAppleMusicUsageDescription` with a clear explanation that Music Nerd identifies the current Apple Music item.
2. Prefer requesting permission during deliberate in-app onboarding, before the first Siri request.
3. Check `MusicAuthorization.currentStatus` in the resolver.
4. If authorization is absent, return a dialog that asks the user to open Music Nerd and grant access. Do not attempt a confusing permission flow during a voice-only interaction if the system cannot present it reliably.

### Primary resolver

Illustrative Swift; compile and adjust against the current Xcode 27 SDK:

```swift
import Foundation
import MusicKit

enum CurrentPlaybackError: Error {
    case authorizationRequired
    case nothingPlaying
    case unsupportedItem
    case insufficientMetadata
}

struct CurrentPlaybackItem: Sendable {
    let appleMusicID: String?
    let title: String
    let artistName: String?
    let albumTitle: String?
    let kind: Kind

    enum Kind: Sendable {
        case song
        case musicVideo
    }
}

struct MusicKitCurrentPlaybackResolver: CurrentPlaybackResolving {
    func currentItem() async throws -> CurrentPlaybackItem {
        guard MusicAuthorization.currentStatus == .authorized else {
            throw CurrentPlaybackError.authorizationRequired
        }

        guard let entry = SystemMusicPlayer.shared.queue.currentEntry else {
            throw CurrentPlaybackError.nothingPlaying
        }

        switch entry.item {
        case .song(let song):
            return CurrentPlaybackItem(
                appleMusicID: song.id.rawValue,
                title: song.title,
                artistName: song.artistName,
                albumTitle: song.albumTitle,
                kind: .song
            )

        case .musicVideo(let video):
            return CurrentPlaybackItem(
                appleMusicID: video.id.rawValue,
                title: video.title,
                artistName: video.artistName,
                albumTitle: nil,
                kind: .musicVideo
            )

        case nil:
            // entry.title and entry.subtitle may support a conservative
            // metadata fallback, but never answer on a low-confidence match.
            throw CurrentPlaybackError.insufficientMetadata

        @unknown default:
            throw CurrentPlaybackError.unsupportedItem
        }
    }
}
```

Phase 0 also needs a non-persisted diagnostic snapshot. `CurrentPlaybackItem` alone is insufficient to prove that a read did not alter playback:

```swift
struct PlaybackDiagnosticSnapshot: Sendable {
    let capturedAt: Date
    let queueEntryID: String?
    let isTransient: Bool
    let transientItemType: String?
    let item: CurrentPlaybackItem?
    let playbackStatus: String
    let playbackTime: TimeInterval
}
```

Build this snapshot from `entry.id`, `entry.isTransient`, `entry.transientItem`, `player.state.playbackStatus`, and `player.playbackTime`. Capture one snapshot immediately before and one immediately after the resolver read. The diagnostic must preserve transient-entry information even when `entry.item` is absent, rather than collapsing every transient case into `insufficientMetadata`.

Account for the passage of time: while playback is active, a small monotonic increase in `playbackTime` is expected. Treat an unexpected seek, restart, status change, queue-entry change, or discontinuity beyond elapsed wall-clock time as a failure; mark a natural track transition during capture as inconclusive and repeat the case.

### Important MusicKit nuance

`SystemMusicPlayer` is the MusicKit player backed by the Music app's state. Reading `queue.currentEntry` does not require Music Nerd to replace the queue or start playback, but the app is accessing the system music player, not a passive global Now Playing API. The API declaration does not guarantee that every radio, local, matched, or transient item will expose a complete catalog object.

Validate behavior on real devices and never call mutating playback methods in this feature. Compare the catalog item, transient queue-entry identity, playback status, and approximate playback position before and after each diagnostic read. Use queue-entry identity for mutation diagnostics only, not as a canonical song identifier. During later Siri end-to-end tests, record Siri/system ducking separately from queue or transport mutation.

### Identity strategy

This is post-gate production work. Phase 0 records the exposed identifiers and metadata but does not query Music Nerd or choose a canonical match.

Resolution order:

1. Exact Apple Music catalog ID mapped to a Music Nerd canonical song ID.
2. Exact external identifier, such as ISRC, if available after an explicit catalog relationship/property fetch.
3. Normalized title + primary artist + album/release context.
4. Conservative fuzzy match with a confidence threshold.
5. Refuse to answer when ambiguous.

Do not use `MusicPlayer.Queue.Entry.id` as the canonical song ID. It identifies the queue entry and is not a durable catalog or Music Nerd identity.

Store a crosswalk such as:

```text
MusicNerdSongID
  <-> AppleMusic MusicItemID + storefront
  <-> ISRC (where valid)
  <-> MusicBrainz recording/release IDs (if used)
  <-> internal aliases and edition relationships
```

Handle edition ambiguity explicitly: live versions, remasters, re-recordings, clean/explicit variants, compilations, and classical recordings can share similar metadata.

## 8. Post-gate V1 App Intents and App Shortcuts

Add these to the existing MusicNerd app target only after Phase 0 passes. Start with the artist action because the current Music Nerd client has artist search, biography, and facts. Add the song action when a song/recording identity and knowledge source exist; until then, any song action must be clearly labeled as a deterministic prototype and must not imply song-specific knowledge it does not have.

The intended production actions are:

- `ExplainCurrentArtistIntent`
- `ExplainCurrentSongIntent`, after the song-data gate passes

Illustrative shape:

```swift
import AppIntents

// Add only after the song identity and grounded-data gate passes.
struct ExplainCurrentSongIntent: AppIntent {
    static let title: LocalizedStringResource = "Tell Me About This Song"
    static let description = IntentDescription(
        "Get Music Nerd context for the song currently playing in Apple Music."
    )
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .background }

    @Dependency
    private var coordinator: CurrentMusicQuestionCoordinator

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let answer = try await coordinator.overview(scope: .song)
        return .result(dialog: IntentDialog("\(answer.spokenText)"))
    }
}

struct ExplainCurrentArtistIntent: AppIntent {
    static let title: LocalizedStringResource = "Tell Me About This Artist"
    static let description = IntentDescription(
        "Get Music Nerd context for the artist currently playing in Apple Music."
    )
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .background }

    @Dependency
    private var coordinator: CurrentMusicQuestionCoordinator

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let answer = try await coordinator.overview(scope: .artist)
        return .result(dialog: IntentDialog("\(answer.spokenText)"))
    }
}
```

App Shortcut shape:

```swift
struct MusicNerdAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Add this shortcut only after the song-data gate passes.
        AppShortcut(
            intent: ExplainCurrentSongIntent(),
            phrases: [
                "Ask \(.applicationName) about this song",
                "Tell me about this song using \(.applicationName)"
            ],
            shortTitle: "About This Song",
            systemImageName: "music.note"
        )

        AppShortcut(
            intent: ExplainCurrentArtistIntent(),
            phrases: [
                "Explain the current artist with \(.applicationName)",
                "Describe the artist playing with \(.applicationName)",
                "Get current artist details from \(.applicationName)",
                "Start an artist briefing with \(.applicationName)"
            ],
            shortTitle: "About This Artist",
            systemImageName: "person.wave.2"
        )
    }
}
```

Use the exact phrase syntax accepted by the current SDK. Test semantic variants, but retain the app name in every first-turn phrase.

The code above is illustrative. The intent and shortcuts-provider types can remain available at the app's iOS 18.2 minimum; gate only `supportedModes` on iOS 26 or later and any later SDK-only property at its own availability. `supportedModes` replaces the deprecated `openAppWhenRun` in current SDKs, dynamic dialog text must use a localized interpolation accepted by `IntentDialog`, and `@Dependency` requires explicit dependency registration.

### Dialog design

- Keep the default spoken response to roughly 2–4 sentences.
- Lead with the fact most specific to the current recording.
- Avoid citation-like URL reading in voice output.
- Offer a concise recovery message rather than raw errors.
- If the answer is long, speak the summary and offer an app deep link or snippet for details.
- Account for voice-only devices such as AirPods.

Suggested failure dialogs:

| Condition | Dialog |
|---|---|
| Music access not granted | “Open Music Nerd once to allow Apple Music access, then try again.” |
| Nothing playing | “I couldn't find a song playing in Apple Music.” |
| Unsupported media | “Music Nerd can explain songs and music videos, but not this item yet.” |
| Ambiguous identity | “I found more than one recording with that title. Open Music Nerd to choose the right one.” |
| Network unavailable | “I found the song, but Music Nerd can't reach its knowledge service right now.” |
| No knowledge record | “I found the song, but Music Nerd doesn't have an explanation for it yet.” |

## 9. Deferred research — Music Nerd App Entity strategy

This section is excluded from Phase 0 and the first production V1. Revisit it after the current-item resolver, artist intent, and production identity model are proven. Music Nerd currently has a durable artist ID but not the canonical song/recording identity required for a trustworthy song entity.

Expose narrow system-facing adapters, not the full backend graph.

### Stable identifiers

- `MusicNerdArtistEntity.id` should be Music Nerd's durable canonical artist ID.
- `MusicNerdSongEntity.id` should be Music Nerd's durable canonical recording/song ID.
- Apple Music IDs, ISRCs, and other service IDs are aliases, not the primary entity ID.
- If the same durable identifier works across devices, consider the SDK's current `SyncableEntity` guidance after V1.

### Artist entity

Use the `.audio.artist` App Entity schema and conform to `IndexedEntity` for the subset that will be indexed.

Candidate fields:

- schema-required artist name and identifiers
- display subtitle, artwork, and deep-link URL
- short biography or editorial summary
- origin / scene
- active years
- genres
- influences
- associated acts and collaborators
- high-value credits or role descriptors

### Song entity

Use the `.audio.song` App Entity schema and conform to `IndexedEntity` for the indexed subset.

Candidate fields:

- schema-required title, artist, album, and identifiers
- Music Nerd canonical ID
- Apple Music ID and storefront alias
- ISRC where present and appropriate
- release date / original release date
- composers, performers, producers, and other credits
- version/edition descriptor
- short significance or recording-context summary
- deep-link URL and artwork

### Scaffold guidance

Start from Xcode 27's `audio_artist` and `audio_song` schema snippets. The following is intentionally schematic rather than a promise of exact beta-SDK conformance:

```swift
@AppEntity(schema: .audio.artist)
struct MusicNerdArtistEntity: IndexedEntity {
    static let defaultQuery = MusicNerdArtistQuery()

    let id: String
    var name: String

    @Property(indexingKey: \.textContent)
    var shortBiography: String?

    var displayRepresentation: DisplayRepresentation { /* ... */ }
}

@AppEntity(schema: .audio.song)
struct MusicNerdSongEntity: IndexedEntity {
    static let defaultQuery = MusicNerdSongQuery()

    let id: String
    var title: String
    // Add the exact schema-required artist/album properties generated by Xcode.

    @Property(indexingKey: \.textContent)
    var contextSummary: String?

    var displayRepresentation: DisplayRepresentation { /* ... */ }
}
```

### Entity query guidance

Implement identifier resolution first. Add only the query protocols needed by the product:

- exact identifiers for intent/result restoration
- suggested/recent entities for Shortcuts pickers
- an indexed query for Spotlight reindexing
- server-backed or string query paths only when the local index cannot represent the catalog

Avoid fetching an entire remote catalog to populate suggestions.

## 10. Deferred research — Spotlight indexing strategy

Spotlight is excluded from Phase 0 and the first production V1.

Spotlight should contain the Music Nerd content most relevant to the user, not the entire service catalog.

### Recommended first indexed set

- favorited artists and songs
- recently viewed artist/song pages
- saved recommendations
- downloaded or offline knowledge packs
- followed artists
- optionally, a bounded recent-listening set when the user has opted into that behavior

### Indexing mechanics

1. Make the entity conform to `IndexedEntity`.
2. Mark only useful, licensed properties for indexing.
3. Use a named `CSSearchableIndex`, not the default index outside early prototyping.
4. Call `indexAppEntities(_:priority:)` for adds and updates.
5. Delete stale entities when the source record is removed or no longer relevant.
6. Adopt `IndexedEntityQuery` so Spotlight can request reindexing.
7. Provide an `OpenIntent` or equivalent deep-link action for each indexed entity type.
8. Assign relevance carefully; favorites and recent items can receive higher priority than incidental views.

### Privacy and content boundaries

- Index only content the user would reasonably expect to be discoverable through system search and Siri.
- Do not index private listening notes or history without an explicit product decision and clear controls.
- Verify content licensing permits local semantic indexing.
- Provide an in-app way to clear or rebuild the Music Nerd index.
- Keep entities compact; put long-form content behind a deep link or service lookup.

### Expected benefit

Indexed, schematized entities can support semantic retrieval and questions over their donated properties, for example:

- “Find the Japanese artists I saved in Music Nerd.”
- “Which Music Nerd artist I looked at was connected to krautrock?”
- “Open the Music Nerd page for the producer I viewed yesterday.”

Do not assume that indexing alone makes Music Nerd the source for an unqualified question about whatever Apple Music is currently playing. Current-context resolution and provider selection are separate problems.

## 11. Deferred research — Now Playing annotations and cross-app transfer

### What is documented

An app that publishes Now Playing metadata through `MPNowPlayingInfoCenter` can add entity identifiers under `MPNowPlayingInfoPropertyAppEntityIdentifiers`. This lets the system associate the publisher's current media with App Entities.

Music Nerd can use this if it later becomes a playback or spoken-audio app with its own Now Playing session.

### What Music Nerd cannot do

Music Nerd cannot add its entity identifiers to Apple Music's `MPNowPlayingInfoCenter.nowPlayingInfo`. That dictionary belongs to the app publishing the Now Playing experience.

### Transferable and `IntentValueRepresentation`

Use these features where there is a documented representation contract:

- `Transferable` provides representations that can cross process/app boundaries.
- `IntentValueRepresentation` translates between an App Entity and a compatible system intent value.
- Import can either match an existing Music Nerd entity through an appropriate value query or create a new transient/local value where the product allows it.

Do not invent an audio bridge. A file/JSON transferable representation does not prove that Siri can feed an Apple Music song into a Music Nerd entity parameter. Adopt a media `IntentValueRepresentation` only if the shipping iOS 27 SDK and documentation define a suitable type and the end-to-end test succeeds.

### Experimental cross-app spike

After V1 works, run a time-boxed experiment:

1. Inspect Xcode 27's Audio schema entity templates and media common types.
2. Create an experimental intent that accepts the documented compatible audio value/entity type, if one exists.
3. Start Apple Music playback.
4. Invoke Siri with explicit Music Nerd wording and a deictic reference: “Ask Music Nerd about this song.”
5. Record whether Siri passes a structured Apple Music identity, asks for disambiguation, ignores the parameter, or fails routing.
6. Repeat across device lock state, locales, AirPods, and multiple iOS 27 seeds.
7. Keep the feature behind a flag until Apple documents the contract or the behavior is stable enough for the product's risk tolerance.

Passing one demo is not a platform guarantee.

## 12. Deferred research — Interaction donations

Donate only genuine, completed, schema-conforming actions that happen through Music Nerd's own UI.

Good candidates depend on the schemas Music Nerd actually adopts. Possible examples include opening a Music Nerd entity, performing an eligible in-app search, or executing a real audio action if Music Nerd later provides playback functionality.

Rules:

- Donate after the user action succeeds, not merely after a tap begins.
- Do not donate actions invoked through Siri or Shortcuts; the system already knows about those interactions.
- Do not flood the system with passive scrolls, repeated background refreshes, or fabricated “preference” events.
- Treat donations as relevance and personalization hints, not deterministic routing rules.
- Include donation behavior in privacy review and analytics documentation.

Interaction donations may help Apple Intelligence learn how the user tends to use Music Nerd, but they do not create a generic preferred music knowledge provider role.

## 13. Deferred research — Conversational follow-up goals

The aspirational experience is:

```text
User: “Explain the current artist with Music Nerd.”
Music Nerd: “Yellow Magic Orchestra were ...”
User: “Who were the members?”
Music Nerd: “Haruomi Hosono, Ryuichi Sakamoto, and Yukihiro Takahashi.”
User: “What else did Sakamoto make around then?”
Music Nerd: “...”
```

### Product goal

Preserve the resolved song/artist, edition, source, and answer context across turns so later questions can use pronouns and narrower references.

### Do not make this a V1 acceptance criterion yet

Apple Intelligence supports conversational system experiences, and schema-backed entities/results provide structured context. However, there is no documented guarantee that an arbitrary Music Nerd custom intent remains the selected tool for subsequent unqualified questions.

### Prototype plan

1. Return a Music Nerd entity and concise dialog where the current SDK permits.
2. Test whether Siri retains that entity and app attribution on the next turn.
3. Add an explicit free-form intent, such as `AskMusicNerdQuestionIntent(question:)`, with app-named App Shortcut phrases for reliable re-entry.
4. Maintain a short-lived Music Nerd context record containing the resolved canonical IDs and last answer scope. Avoid relying solely on raw conversational text.
5. If implicit Siri follow-up routing is unreliable, require an explicit Music Nerd phrase on each turn or hand off to an in-app conversational view.

Suggested context model:

```swift
struct MusicConversationContext: Sendable, Codable {
    let songID: String?
    let artistID: String?
    let albumID: String?
    let editionID: String?
    let sourceAppleMusicID: String?
    let createdAt: Date
}
```

Use a short TTL so “this song” does not accidentally refer to stale playback after the track changes.

## 14. Implementation sequence

### Status — August 30, 2026

- Phase 0 exit gate approved after the project owner completed the manual physical-device matrix and verified that Music Nerd did not mutate Apple Music playback.
- Phase 1 is complete. The production slice reads current playback, resolves one exact normalized Music Nerd artist identity, and composes a grounded artist answer without App Intents code.
- Phase 2 implementation and automated validation are complete. The app now exposes one grounded artist App Intent, four explicit Music Nerd App Shortcut phrases, focused user-facing dialogs, and a dedicated iOS 27 `AppIntentsTesting` bundle and test plan.
- Direct execution of **About This Artist** in Shortcuts succeeded on a physical device for Portishead and returned a grounded answer. The original “Ask Music Nerd about this artist” phrase routed to Siri's in-app search fallback, while “Tell me about this artist using Music Nerd” did not visibly route.
- The shortcut phrases were replaced with distinct, verb-led variants, and the app now refreshes App Shortcut parameters at launch. On the initial build `1` install, all four revised phrases failed silently through Siri despite complete generated NLU assets and direct Shortcuts execution continuing to work.
- The clone's build number was `1`, below the existing App Store build `9` for the same bundle identifier. After installing and launching a clean signed `1.0 (10)` device build, the exact phrase “Start an artist briefing with Music Nerd” successfully routed through Siri and returned the grounded Portishead answer. This confirms physical-device Siri routing for the registered App Shortcut; it strongly implicates stale version/index state in the earlier failures without proving that as the sole cause.
- The removed legacy phrase “Ask Music Nerd about this artist” opens Music Nerd instead of invoking the artist intent. Treat that as Siri fallback behavior, not a supported phrase. The remaining registered phrase variants and the foreground/background/terminated playback-safety matrix remain pending.
- Product decision: requiring users to remember a specific Music Nerd phrase is unacceptable. The custom App Shortcut path therefore fails the primary Siri product gate even though its technical execution path works. Stop before Phase 3; keep remaining lifecycle checks deferred unless this intent is retained as an optional secondary surface.
- Device-specific Phase 0 evidence remains with the manual test record; this plan does not invent device or OS details that were not checked into the repository.

### Phase 0 — Feasibility spike

- On a dedicated feature branch, add an isolated debug-only current-playback resolver and diagnostic screen to the existing `MusicNerd` app target.
- Do not create another app target or Xcode project, and do not raise the app's iOS 18.2 deployment target.
- Wrap the diagnostic screen and its navigation/wiring in `#if DEBUG` or otherwise exclude it from release builds.
- Verify signing, provisioning, the existing App ID's MusicKit App Service configuration in the developer portal, and `NSAppleMusicUsageDescription`. Update the purpose text so it explains that Music Nerd identifies the current Apple Music item, not only that it can play music.
- Request authorization from the app UI.
- Keep the resolver separate from the existing playback-mutating `AppleMusicService`; Phase 0 must expose no queue or transport commands.
- On two or more physical devices, confirm that `SystemMusicPlayer.shared.queue.currentEntry` sees the item currently playing in Apple Music. Test a supported baseline OS and iOS 27 where available so the mature MusicKit behavior is measured independently of later iOS 27 Siri integration.
- Log only non-sensitive diagnostic fields needed for the spike.
- Keep diagnostics ephemeral and local. Do not call the backend, persist playback snapshots, or add production analytics.
- Compare item identity, queue-entry identity, transient-entry state, playback status, and approximate position before and after each read. Verify that Music Nerd does not pause, play, seek, skip, restart, or replace playback.
- Exercise songs, music videos, radio/autoplay items, locally matched content, and transient queue entries.

**Exit gate:** current-item resolution is reliable enough to justify the rest of the V1.

### Phase 1 — Production artist identity and knowledge integration

- Define `CurrentPlaybackItem`, `MusicIdentity`, `KnowledgeScope`, and `KnowledgeAnswer`.
- Promote the proven resolver into production code without adding mutating player behavior.
- Add the identity-crosswalk seam, but leave it empty in production until Phase 3 provides canonical recording data. Never treat a queue-entry ID as a durable identity.
- Resolve the artist through the existing Music Nerd artist search. Consider every returned candidate, accept only one exact normalized-name match with a real Music Nerd artist ID, and reject ambiguous or low-confidence results.
- Add a grounded artist-knowledge service over the existing biography and fact APIs. Do not route this work through `OpenAIService`, generate facts, or claim song-specific knowledge.
- Keep the current-playback knowledge path out of the persistent SwiftData enrichment cache so invoking it does not create a new on-disk listening trace. Existing enrichment callers may retain their persistent-cache behavior.
- Add short-lived in-memory caching, cooperative cancellation, a 3-second artist-identity timeout, and a 7-second knowledge timeout. Use a five-minute TTL, a 0.9 minimum confidence threshold, and at most four sentences or 600 characters as provisional prototype policy. Reuse an expired identity and grounded answer only for the same stable playback item after an offline or timeout refresh failure.
- Add a coordinator that always reads current playback before resolving identity or consulting knowledge caches.
- Build deterministic unit tests independent of Siri and MusicKit.
- Keep App Intents, App Shortcuts, Siri, and `AppIntentsTesting` in Phase 2.

**Exit gate:** passed with focused domain/cache tests, related enrichment/container regression tests, Debug and Release simulator builds, and a signed physical-device Debug build.

### Phase 2 — Prototype artist App Intent

- Implement the artist intent first as a thin adapter over the existing grounded artist service.
- Keep the song intent out of production until Phase 3's song/recording identity and knowledge prerequisites exist. A temporary stub must be labeled as prototype output.
- Add App Shortcut phrases that explicitly name Music Nerd.
- Return `ProvidesDialog`; add a snippet only if it materially improves the interaction.
- Provide specific permission, no-playback, ambiguity, offline, and no-data dialogs.
- Register App Intent dependencies explicitly and availability-gate iOS 26/27-only declarations while preserving the app's iOS 18.2 minimum.
- Add a dedicated iOS 27 UI-testing bundle and test plan for `AppIntentsTesting`; keep it separate from the existing iOS 18.2 UI-test target and Fastlane plans.

**Implementation status:** automated work is complete. The Release metadata contains only the production artist intent and its four app-named phrases; debug scenario controls are excluded. Focused unit tests, the dedicated App Intents integration tests, related domain regressions, Debug/Release simulator builds, and a signed physical-device Debug build pass. Physical testing proved direct Shortcuts execution and one exact Siri trigger, which was sufficient to expose the product limitation.

**Technical result:** the artist action works from Shortcuts and through one exact registered Siri phrase. **Product result:** failed—the reliable path requires an app-specific learned phrase. Do not proceed to Phase 3 on the basis of this interaction model.

### Phase 3 — Production identity and answer quality

- Treat the current backend gap as a prerequisite: the iOS client can search artists and fetch artist biographies/facts, but it does not yet have canonical recording IDs, edition modeling, confidence scoring, or a song-explanation endpoint.
- Build the Apple Music-to-Music Nerd crosswalk.
- Add metadata fallback and edition disambiguation.
- Add `ExplainCurrentSongIntent` only after the crosswalk and grounded song-level service pass their own tests, then repeat the Phase 2 Shortcuts/Siri exit gate for it.
- Ground every answer in Music Nerd data.
- Add latency budgets and graceful degradation.
- Validate voice-length, pronunciation, and unsupported-content behavior.

### Phase 4 — Deferred: App Entities and Spotlight

- Generate `.audio.artist` and `.audio.song` scaffolds from Xcode.
- Use stable Music Nerd IDs and strong display representations.
- Add identifier queries and deep links.
- Index a bounded, user-relevant corpus using a named index.
- Add reindexing and deletion behavior.

### Phase 5 — Deferred: donations and Music Nerd UI annotations

- Annotate Music Nerd's own artist/song UI with App Entities.
- Donate only eligible completed UI actions.
- Add privacy and index-management controls.

### Phase 6 — Deferred: cross-app and follow-up experiments

- Run the Apple Music Now Playing entity-transfer spike.
- Test typed entity results and follow-up retention.
- Ship only behavior supported by documentation or strong, repeatable device evidence.

### Phase 7 — Hardening

- Stabilize the dedicated iOS 27 App Intents UI-test target from Phase 2 and add CI coverage when the toolchain is stable.
- Run manual Siri and real-device MusicKit matrices.
- Revalidate on the final iOS 27 SDK.
- Begin with local diagnostics. Production metrics for invocation success, identity confidence, answer latency, and categorized failures require separate product and privacy approval; never log private utterance content by default.

## 15. Testing plan

### Phase 0 physical-device matrix

Run the existing MusicNerd debug build on at least two physical devices. Cover a supported baseline OS and iOS 27 where available, MusicKit authorization states, catalog songs, music videos, radio/autoplay, local or matched items, and transient entries while the diagnostic screen is visible. For every case, capture the current item, queue-entry identity, transient-entry state, playback status, and approximate position before and after the read.

Do not add App Intents, Siri, backend, Spotlight, or entity testing until this matrix passes the Phase 0 exit gate.

### A. Domain unit tests

Test without App Intents:

- Phase 1: exact artist-name normalization and Music Nerd artist-ID resolution
- Phase 1: multiple exact candidates, low-confidence candidates, and missing artist metadata
- Phase 1: empty recording crosswalk fallback to the conservative artist resolver
- Phase 1: confidence threshold behavior
- artist extraction from a song
- caching, expiry, and stale offline fallback
- service timeout, cancellation, and offline fallback
- grounded response formatting and maximum spoken length
- Phase 3: exact Apple Music recording-ID mapping, missing crosswalk fallback, and live/remaster/version ambiguity

### B. AppIntentsTesting integration tests

After the feasibility gate and intent implementation, create an iOS 27 UI Testing target in the existing Xcode project, signed by the same development team as the app. Instantiate `IntentDefinitions` with Music Nerd's bundle identifier; tests locate definitions by name and execute them out-of-process through the real App Intents stack.

Cover:

- discovery of every implemented V1 intent definition
- successful `perform()` results against deterministic seeded services
- dialog/result shape
- debug-only setup/reset intents where needed, marked `isDiscoverable = false` and excluded from release builds

Extend this suite in later milestones to cover entity resolution by stable ID, suggested/recent entity queries, transferable export/import round trips, Spotlight indexing and reindexing, and Music Nerd view annotations.

Do not rely on AppIntentsTesting to seed a real Apple Music queue. Keep MusicKit queue validation in a physical-device integration suite.

### C. Shortcuts tests

- Confirm every implemented action appears with the correct title, icon, and description.
- Run each action with the app foregrounded, backgrounded, and terminated.
- Confirm no unexpected app launch for inline intents.
- Confirm dialog behavior for every error state.

### D. Deferred Spotlight tests

- Search exact artist/song names.
- Search semantic descriptions represented in indexed properties.
- Open a result into the correct Music Nerd destination.
- Update and delete records, then verify stale results disappear.
- Clear/rebuild the index.

### E. Siri end-to-end matrix

Test on physical devices with current iOS 27 seeds:

| Dimension | Cases |
|---|---|
| Invocation | canonical phrase, semantic paraphrases, app name first/last |
| Playback | playing, paused, stopped, track changes during request |
| Item | catalog song, library song, music video, radio/autoplay, local/matched item, transient item |
| App state | foreground, background, terminated |
| Device state | unlocked, locked, AirPods/voice-only |
| Connectivity | online, high latency, offline |
| Authorization | authorized, not determined, denied, restricted |
| Identity | exact, fallback, ambiguous, missing |
| Language | all supported launch locales and artist-name pronunciations |
| Follow-up | implicit pronoun, explicit Music Nerd re-entry, stale context after track change |

Verify on every run:

- the intended Music Nerd action ran
- the correct recording/artist resolved
- Music Nerd issued no playback mutation; any Siri/system ducking was evaluated separately
- answer attribution and dialog were understandable
- errors did not expose implementation details

### F. Regression order

Use this progression for the first production V1:

```text
Phase 0 physical-device gate
    -> Domain unit tests
    -> AppIntentsTesting
    -> Shortcuts
    -> Siri end-to-end
```

Entity, Spotlight, transfer, donation, and annotation tests belong to their later milestones and do not block the first artist-intent V1.

Language-model orchestration is the least deterministic layer, so validate the typed integration below it first.

## 16. Observability

For Phase 0, use only ephemeral on-screen diagnostics and a manual results document. Do not persist listening snapshots or add analytics to the shipping app. The events below are candidates for later production observability and require product/privacy approval.

Capture privacy-preserving events such as:

- intent invoked: song or artist
- current entry present: yes/no
- MusicKit item kind
- resolution method: exact ID / external ID / metadata / failed
- confidence bucket, not raw query text
- answer source: cache / API / fallback
- latency by stage
- result category: success / authorization / no playback / ambiguity / no record / network / internal
- playback state before and after, only as a mutation safety check

Do not log raw Siri utterances, listening history, or full response text by default. Review analytics retention and user controls with privacy/legal stakeholders.

## 17. Open questions and risks

### Platform and beta risk

- The architecture mixes mature MusicKit/App Shortcut APIs with iOS 27 beta App Schema and testing APIs. Availability-gate the latter rather than treating the entire prototype as iOS 27-only.
- Will exact App Schema requirements or macro expansion change before the final iOS 27 SDK?
- Are the relevant Siri AI capabilities available on every intended device, language, and region at launch?
- Can both intents execute reliably while the app is terminated and under lock-screen constraints?
- Which execution target is best for MusicKit, authentication, and network access in the final SDK?

### MusicKit risk

- Can the read-only resolver remain completely separate from the existing playback-mutating `AppleMusicService`?
- Does `SystemMusicPlayer.shared.queue.currentEntry` expose every Apple Music item type needed by the product?
- How often is `entry.item` absent or transient in real playback?
- Are catalog relationships/extended properties available quickly enough inside the intent budget?
- What behavior occurs for local files, matched uploads, radio, and music videos?
- When Siri ducks or temporarily pauses audible playback, does the original item, queue, status, and position resume without any Music Nerd-issued mutation?

### Identity and data risk

- The current iOS client is artist-oriented. What backend endpoint and canonical model will support trustworthy song- or recording-specific explanations?
- What is the canonical Music Nerd distinction between work, recording, release, and edition?
- Which external IDs are licensed and reliable enough for crosswalking?
- How are artist collaborations, featured artists, ensembles, and classical composers represented?
- How will the service refuse a low-confidence match rather than answer about the wrong version?

### Siri routing risk

- Which App Shortcut paraphrases reliably preserve explicit Music Nerd routing?
- Does Siri keep Music Nerd entity/app context for a second unqualified turn?
- If Siri knows Apple's Now Playing entity, can it pass any documented structured audio value to Music Nerd?
- Does app preference learned from donations affect eligible schema actions only, or any custom entry point? Do not assume the latter.

### Spotlight and content risk

- Which content is local and relevant enough to index?
- What are the licensing implications of indexing editorial text?
- How quickly must changes and deletions propagate?
- What user controls are required for listening-history-derived indexing?

### Answer quality risk

- What is the source-of-truth policy and citation model?
- Can the answer composer stay within voice latency and length limits?
- How are uncertain or disputed music-history facts expressed?
- What is the deterministic fallback when a language model is unavailable?

## 18. Decisions to preserve

| Decision | Status | Rationale |
|---|---|---|
| Prototype in the existing MusicNerd app target | Accepted | Real bundle, signing, authorization, App Shortcut identity, and lifecycle behavior provide the highest-fidelity evidence |
| Use a dedicated branch and debug-only Phase 0 surface | Accepted | Isolates the spike without creating a second product or polluting release builds |
| Preserve the iOS 18.2 deployment target | Accepted | Core playback and custom App Intent APIs predate iOS 27; newer surfaces can be availability-gated |
| Keep the read-only resolver separate from `AppleMusicService` | Accepted | Makes the no-mutation boundary explicit and auditable |
| Create a standalone prototype app or second Xcode project | Rejected by default | A new bundle duplicates provisioning, permission, and shortcut identity and still requires production retesting |
| Require explicit “Music Nerd” invocation in V1 | Accepted | No documented generic music-knowledge provider registration |
| Read `SystemMusicPlayer.shared.queue.currentEntry` | Accepted for prototype | Most direct documented path to the Music app-backed queue's current entry |
| Never mutate playback in the knowledge feature | Accepted | Music Nerd is commentary, not the player |
| Treat Siri/system audio ducking as Music Nerd mutation | Rejected | Evaluate app-issued queue/transport changes separately from system-managed voice audio |
| Keep App Intents thin over shared services | Accepted | Testability, reuse, and clean execution boundaries |
| Use Music Nerd stable IDs for entities | Accepted | Service IDs and queue-entry IDs are aliases, not canonical domain identity |
| Index a bounded, user-relevant corpus | Accepted | Spotlight is local system retrieval, not a mirror of the global backend |
| Ship a song intent before song-level identity and data exist | Rejected/deferred | Artist data does not support trustworthy song-specific claims |
| Depend on Apple Music entity transfer for V1 | Rejected/deferred | No documented guaranteed cross-app contract for this scenario |
| Guarantee implicit conversational follow-ups in V1 | Rejected/deferred | Needs device evidence and/or a documented routing contract |
| Use Foundation Models for ungrounded music facts | Rejected | Factual knowledge must come from Music Nerd sources |

## 19. Definitions of done

### Phase 0 feasibility spike

- [x] Music authorization is requested in-app with clear purpose text.
- [x] The diagnostic is implemented in the existing MusicNerd app target on a dedicated branch and is excluded from release builds with `#if DEBUG` or equivalent build configuration.
- [x] The app's deployment target remains iOS 18.2; no second app target or Xcode project is created.
- [x] A physical-device spike reads the current Apple Music item through `SystemMusicPlayer.shared.queue.currentEntry`.
- [x] The resolver handles song, music video, missing entry, missing item, denied permission, incomplete metadata, and unsupported items.
- [x] Catalog songs, music videos, radio/autoplay, local or matched content, and transient entries were manually verified on at least two physical devices.
- [x] Before/after evidence shows that Music Nerd never mutates the queue or transport.
- [x] The spike makes no backend calls, persists no playback snapshots, and adds no production analytics.

### Production V1 prototype, contingent on Phase 0

- [x] The production resolver remains separate from playback-mutating services and has deterministic unit tests.
- [x] `ExplainCurrentArtistIntent` calls a grounded shared artist service.
- [x] Phase 2 does not add `ExplainCurrentSongIntent`; it remains gated on canonical recording identity and song-level knowledge.
- [x] Every implemented intent runs from Shortcuts.
- [ ] Every implemented explicit app-named phrase runs through Siri.
- [x] Responses are grounded, concise, and have tested failure dialogs.
- [ ] Identity confidence and latency meet the agreed production thresholds.
- [x] iOS 27 App Intents integration tests cover the implemented intent's discovery, execution, and returned response shape; focused unit tests cover dialog mapping.
- [ ] Manual Siri and MusicKit results are documented by device, OS, and Xcode seed.
- [x] App Entities, Spotlight, cross-app transfer, donations, Foundation Models, and implicit follow-ups remain separate later milestones.

### Phase 1 artist domain integration

- [x] The production playback resolver exposes only read operations and remains separate from `AppleMusicService`.
- [x] Artist lookup considers every candidate and rejects missing, ambiguous, and below-threshold matches.
- [x] The production recording crosswalk seam exists but contains no invented mappings.
- [x] Artist answers use only Music Nerd biography and fact data and remain within four sentences and 600 characters.
- [x] Identity and knowledge use five-minute in-memory caches, deadlines, and cooperative cancellation.
- [x] Offline/timeout fallback is limited to expired entries for the same stable playback identity.
- [x] Current-playback knowledge bypasses the persistent enrichment cache and redacts artist identifiers and raw backend errors from logs.
- [x] Focused domain/cache tests and related enrichment/container regressions pass.
- [x] Debug simulator, Release simulator, and signed physical-device Debug builds pass while preserving the iOS 18.2 deployment target.

### Phase 2 artist App Intent

- [x] `ExplainCurrentArtistIntent` is a thin adapter over `CurrentMusicQuestionCoordinating` with an explicitly registered dependency.
- [x] The app keeps its iOS 18.2 minimum and availability-gates the newer background execution declaration.
- [x] `MusicNerdAppShortcuts` exposes only the artist action with four explicit app-named phrases.
- [x] Authorization, no-playback, unsupported-content, ambiguous-identity, offline/timeout, no-data, cancellation, and unknown failures map to user-facing responses without raw errors.
- [x] A dedicated, serial iOS 27 `AppIntentsTesting` UI-test target and test plan remain separate from the existing iOS 18.2 UI target and Fastlane plans.
- [x] Debug-only scenario setup/reset intents are absent from Release App Intents metadata and executable symbols.
- [x] Focused intent tests, combined Phase 0/1/2 tests, related service regressions, Debug/Release simulator builds, and a signed physical-device Debug build pass.
- [ ] Run the artist action from Shortcuts with Music Nerd foregrounded, backgrounded, and terminated on a physical iPhone. A direct physical-device invocation has passed; the lifecycle matrix remains.
- [x] Invoke “Start an artist briefing with Music Nerd” successfully through Siri on a physical iPhone.
- [x] Record the product decision that a memorized app-specific phrase is a non-starter; the custom App Shortcut is not the primary V1 Siri entry point.
- [ ] If the intent is retained as an optional secondary surface, verify the other three registered phrase variants and complete the lifecycle/playback-safety matrix before shipping that surface.

## 20. Apple developer references

### Deferred iOS 27 / WWDC26 App Intents resources

- [WWDC26: Build intelligent Siri experiences with App Schemas](https://developer.apple.com/videos/play/wwdc2026/240/) — entities, `IndexedEntity`, schema-backed actions, cross-app transfer, onscreen awareness, and testing progression.
- [WWDC26: Explore advanced App Intents features for Siri and Apple Intelligence](https://developer.apple.com/videos/play/wwdc2026/343/) — dialog/snippet responses, interaction donations, structured search, semantic indexing, and contextual cues.
- [WWDC26: Code-along — Make your app available to Siri](https://developer.apple.com/videos/play/wwdc2026/344/) — end-to-end entity, Spotlight, open, onscreen, and Siri integration using the CometCal sample.
- [WWDC26: Validate your App Intents adoption with AppIntentsTesting](https://developer.apple.com/videos/play/wwdc2026/295/) — out-of-process tests for intents, queries, Spotlight, transfer, and annotations.
- [WWDC26 Apple Intelligence guide](https://developer.apple.com/wwdc26/guides/apple-intelligence/) — curated index of the relevant sessions and documentation.

### App Intents, schemas, entities, and Siri

- [Apple Intelligence and Siri AI](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai)
- [Making actions and content discoverable by Apple Intelligence](https://developer.apple.com/documentation/appintents/making-actions-and-content-discoverable-by-apple-intelligence)
- [App schema domains](https://developer.apple.com/documentation/appintents/app-schema-domains)
- [Audio App Schema domain](https://developer.apple.com/documentation/appintents/app-schema-domain-audio)
- [Audio artist entity schema](https://developer.apple.com/documentation/appintents/appschema/audioentity/artist)
- [Audio song entity schema](https://developer.apple.com/documentation/appintents/appschema/audioentity/song)
- [Defining App Entities for custom data types](https://developer.apple.com/documentation/appintents/defining-app-entities-for-your-custom-data-types)
- [Providing contextual cues to Apple Intelligence and Siri](https://developer.apple.com/documentation/appintents/providing-contextual-cues-to-apple-intelligence-and-siri)
- [`MPNowPlayingInfoPropertyAppEntityIdentifiers`](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfopropertyappentityidentifiers)

### Spotlight, transfer, donations, and testing

- [Making App Entities available in Spotlight](https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight)
- [`IndexedEntity`](https://developer.apple.com/documentation/appintents/indexedentity)
- [`IntentValueRepresentation`](https://developer.apple.com/documentation/appintents/intentvaluerepresentation)
- [Donating your app's data and actions to the system](https://developer.apple.com/documentation/appintents/donating-your-apps-data-and-actions-to-the-system)
- [App Intents Testing](https://developer.apple.com/documentation/appintentstesting)
- [Testing your App Intents code](https://developer.apple.com/documentation/appintentstesting/testing-your-app-intents-code)
- [Adopting App Intents to support system experiences sample](https://developer.apple.com/documentation/appintents/adopting-app-intents-to-support-system-experiences)

### Phase 0 MusicKit

- [`SystemMusicPlayer`](https://developer.apple.com/documentation/musickit/systemmusicplayer)
- [`MusicPlayer.Queue`](https://developer.apple.com/documentation/musickit/musicplayer/queue)
- [`MusicPlayer.Queue.currentEntry`](https://developer.apple.com/documentation/musickit/musicplayer/queue/currententry)
- [`MusicPlayer.Queue.Entry`](https://developer.apple.com/documentation/musickit/musicplayer/queue/entry)
- [`MusicPlayer.Queue.Entry.Item`](https://developer.apple.com/documentation/musickit/musicplayer/queue/entry/item-swift.enum)
- [`MusicAuthorization`](https://developer.apple.com/documentation/musickit/musicauthorization)
- [`MusicAuthorization.request()`](https://developer.apple.com/documentation/musickit/musicauthorization/request%28%29)

### Foundation Models

- [Foundation Models framework](https://developer.apple.com/documentation/foundationmodels)
- [Generating content and performing tasks with Foundation Models](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models)

## 21. Next decision for a coding agent

Phase 0 and Phase 1 passed technically. Phase 2 proved that the artist intent executes from Shortcuts and from a registered Siri phrase, but it failed the product requirement because reliable Siri invocation depends on a learned app-specific phrase.

Do not begin Phase 3 or spend more time tuning trigger phrases. The next task is to choose one of these explicitly:

1. Retain **About This Artist** only as an optional Shortcuts, Action Button, automation, or debug surface. If it will ship in any of those roles, finish the lifecycle/playback-safety matrix and polish its displayed response.
2. Run a separate `.system.searchInApp` spike if opening Music Nerd to relevant artist search results is an acceptable experience. Its acceptance criteria must not claim that it returns a background current-artist answer in Siri.
3. If neither optional shortcuts nor an app-opening search experience satisfies the product, remove the production App Shortcut exposure, preserve the read-only current-playback and grounded-knowledge work for an app-native entry point, and defer Siri until Apple provides a semantically matching schema.

Do not add `ExplainCurrentSongIntent`, a populated recording crosswalk, cross-app transfer, donations, Foundation Models, or implicit follow-up behavior until a viable no-incantation entry point has passed its own product gate.
