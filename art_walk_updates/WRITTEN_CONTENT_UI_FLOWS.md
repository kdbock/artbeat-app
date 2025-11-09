# Written Content & Reading UI Flows

## Overview
This document outlines the user interface flows for reading written content, comics, and audiobooks in ArtBeat.

---

## 1. Discovery & Browsing

### 1.1 Explore Tab Enhancements

**Current State**: Visual-focused grid of artwork

**New State**: Multi-content-type tabs
```
┌─────────────────────────────────┐
│ [Visual] [Written] [Comics] [Audio] 
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │  The Last Journey           │ │
│ │  📖 Book • 85,000 words     │ │
│ │  ⏱️ ~250 min read           │ │
│ │  ⭐ 4.8 • $4.99             │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │  The Mysterious Island      │ │
│ │  📺 Series • Chapter 5/12   │ │
│ │  ⏱️ ~15 min/chapter         │ │
│ │  🔄 Next: Monday            │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**Content Cards Display**:
- **Visual Art**: Image + artist name + price
- **Written Work**: Cover + title + word count + reading time + price
- **Comic**: Cover + episode count + format (webtoon/traditional) + reading time
- **Audio**: Cover + narrator + duration + price

### 1.2 Search Filters (Written Content)

```
Filters:
├─ Content Type
│  ├─ Book (Complete)
│  ├─ Series (Ongoing)
│  ├─ Short Story
│  ├─ Comic
│  └─ Audiobook
├─ Genre
│  ├─ Romance
│  ├─ Fantasy
│  ├─ Mystery
│  └─ Sci-Fi
├─ Reading Time
│  ├─ Under 30 min
│  ├─ 30-60 min
│  ├─ 1-3 hours
│  └─ 3+ hours
├─ Price
│  ├─ Free
│  ├─ Under $2.99
│  ├─ $2.99-$7.99
│  └─ $7.99+
└─ Release Status
   ├─ Completed
   └─ Ongoing
```

---

## 2. Artwork Detail Screen (Written)

### 2.1 Single Book / Story

```
┌──────────────────────────────────┐
│ ◄ The Last Journey        ⋮      │
├──────────────────────────────────┤
│                                  │
│        [BOOK COVER]              │
│        (Large preview)           │
│                                  │
├──────────────────────────────────┤
│ The Last Journey                 │
│ by Sarah Chen                    │
│ ⭐ 4.8 (342 reviews)             │
│ 📖 Novel • 85,000 words          │
│ ⏱️ ~250 minutes estimated        │
│                                  │
│ [PURCHASE] or [READ FREE*]       │
│                                  │
├──────────────────────────────────┤
│ Description                      │
│ An epic fantasy novel about      │
│ adventure and discovery across  │
│ ancient lands...                 │
│                                  │
│ Genres: Fantasy, Adventure, Epic │
│                                  │
├──────────────────────────────────┤
│ By the Author                    │
│ [Avatar] Sarah Chen              │
│ ⭐ Author • 12.4K followers     │
│ [FOLLOW] [MESSAGE]               │
│                                  │
├──────────────────────────────────┤
│ Contents (17 Chapters)           │
│                                  │
│ Introduction                 5 min│
│ ► Chapter 1: New Beginnings  8 min│
│ Chapter 2: The Journey       9 min│
│ Chapter 3: First Challenge   7 min│
│                                  │
│ [VIEW ALL CHAPTERS]              │
│                                  │
├──────────────────────────────────┤
│ Engagement                       │
│ ❤️ 1.2K Likes  💬 87  📤 234    │
│                                  │
│ [Like] [Comment] [Share]         │
│                                  │
├──────────────────────────────────┤
│ Community                        │
│ Top Review: ⭐⭐⭐⭐⭐          │
│ "A masterpiece!" - Marcus L.     │
│                                  │
│ [READ ALL REVIEWS]               │
│                                  │
└──────────────────────────────────┘
```

### 2.2 Serialized Story / Series

```
┌──────────────────────────────────┐
│ ◄ The Mysterious Island   ⋮      │
├──────────────────────────────────┤
│        [SERIES COVER]            │
├──────────────────────────────────┤
│ The Mysterious Island            │
│ by Mystery Author                │
│ 📺 Series • 12 Chapters          │
│ ⏱️ ~15 min per chapter           │
│ 🔄 Released: Mondays             │
│ Next Update: 2 days              │
│                                  │
│ [START READING] [SUBSCRIBE]      │
│                                  │
├──────────────────────────────────┤
│ Series Progress                  │
│ ████████░░░░░░░░░░░░  5/12 (42%) │
│                                  │
│ Latest Chapter Unlocked:         │
│ Chapter 5: The Clue              │
│ Released: 2 hours ago            │
│ 3,200 words • 16 min             │
│                                  │
├──────────────────────────────────┤
│ Release Schedule                 │
│ ✓ Chapter 1    Oct 1            │
│ ✓ Chapter 2    Oct 8            │
│ ✓ Chapter 3    Oct 15           │
│ ✓ Chapter 4    Oct 22           │
│ ✓ Chapter 5    Oct 29           │
│ ○ Chapter 6    Nov 5   (3 days) │
│ ○ Chapter 7    Nov 12          │
│ ○ Chapter 8    Nov 19          │
│                                  │
├──────────────────────────────────┤
│ Chapters (5 Released)            │
│                                  │
│ ✓ Chapter 1: The Arrival     5 min│
│ ✓ Chapter 2: Strange Sounds  7 min│
│ ✓ Chapter 3: Discovery       6 min│
│ ✓ Chapter 4: The Map         8 min│
│ ✓ Chapter 5: The Clue   🆕  16 min│
│ 🔒 Chapter 6: TBD            TBD  │
│                                  │
│ [SUBSCRIBE TO UNLOCK ALL]        │
│                                  │
├──────────────────────────────────┤
│ Engagement & Analytics           │
│ 👥 5.2K Readers                  │
│ 📈 Trending #3 in Mystery        │
│ ❤️ 4.7 Avg Rating                │
│                                  │
└──────────────────────────────────┘
```

---

## 3. Text Reader Screen

### 3.1 Main Reading View

```
┌──────────────────────────────────┐
│ Chapter 3: Discovery        ≡    │
├──────────────────────────────────┤
│                                  │
│  Progress: ███░░░░░░░░░░  34%    │
│                                  │
│  Time Spent: 8 min               │
│  Est. Time Left: 12 min          │
│                                  │
├──────────────────────────────────┤
│                                  │
│  The old castle stood high        │
│  above the valley, its stone      │
│  walls weathered by centuries     │
│  of wind and rain. Marcus         │
│  paused at the gate, his heart    │
│  pounding in his chest.           │
│                                  │
│  "This is it," whispered Elena   │
│  from beside him. "The place      │
│  of legends."                     │
│                                  │
│  [Bookmark annotation appears]   │
│  💬 "Beautiful description"       │
│                                  │
│  He took a deep breath and        │
│  pushed the heavy gates open.     │
│  A rusty squeal echoed through    │
│  the courtyard as dust swirled    │
│  in the afternoon light...        │
│                                  │
│  [scroll for more]               │
│                                  │
├──────────────────────────────────┤
│ [🔖] [🔤] [☀️] [⋮]              │
│Bookmark Font  Dark  Options      │
└──────────────────────────────────┘
```

### 3.2 Reader Controls (Bottom Sheet)

```
┌──────────────────────────────────┐
│ Chapter 3: Discovery        ✕    │
├──────────────────────────────────┤
│                                  │
│ [TEXT SIZE CONTROLS]             │
│ Aa    [—]  Aa    [+]  AAA        │
│ Small Default    Large           │
│                                  │
│ [FONT SELECTION]                 │
│ ○ Default   ○ Serif   ○ Sans    │
│                                  │
│ [COLOR SCHEME]                   │
│ ○ Light    ○ Sepia   ○ Dark    │
│                                  │
│ [LINE SPACING]                   │
│ Compact    [——]    Spacious      │
│                                  │
│ [MARGINS]                        │
│ Narrow     [——]    Wide         │
│                                  │
│ [TYPOGRAPHY]                     │
│ Justify Text      [Toggle]       │
│ Show Page Numbers [Toggle]       │
│                                  │
│                 [SAVE SETTINGS]  │
│                                  │
└──────────────────────────────────┘
```

### 3.3 Bookmark & Notes

```
┌──────────────────────────────────┐
│ 🔖 My Bookmarks                 │
├──────────────────────────────────┤
│                                  │
│ Chapter 2, Page 12               │
│ Quote: "The old castle stood..." │
│ Note: "Beautiful description"    │
│ Saved: Oct 29 • 3:45 PM          │
│ [GOTO] [EDIT] [DELETE]           │
│                                  │
│ Chapter 1, Page 8                │
│ Quote: "A rusty squeal echoed..." │
│ Note: (none)                     │
│ Saved: Oct 28 • 9:12 AM          │
│ [GOTO] [EDIT] [DELETE]           │
│                                  │
│                 [ADD NEW BOOKMARK]│
│                                  │
└──────────────────────────────────┘
```

---

## 4. Comic/Webtoon Reader

### 4.1 Vertical Strip (Webtoon)

```
┌──────────────────────────────────┐
│ ◄ Episode 5: Plot Twist    ⋮     │
├──────────────────────────────────┤
│                                  │
│      [PANEL 1]                   │
│      [ARTWORK]                   │
│      [Comic dialogue]            │
│      [Progress: 15%]             │
│                                  │
│      [PANEL 2]                   │
│      [ARTWORK]                   │
│      [Comic dialogue]            │
│                                  │
│      [PANEL 3]                   │
│      [ARTWORK]                   │
│      [Comic dialogue]            │
│      [Progress: 42%]             │
│                                  │
│      [PANEL 4]                   │
│      [ARTWORK]                   │
│      [Comic dialogue]            │
│      [Progress: 68%]             │
│                                  │
│      [PANEL 5]                   │
│      [ARTWORK]                   │
│      [CLIFFHANGER]               │
│      [Progress: 100% - TO BE CONTINUED...]
│                                  │
├──────────────────────────────────┤
│ ❤️ 2.3K  💬 156  📤 89           │
│ [Previous] [Next Episode]        │
│                                  │
└──────────────────────────────────┘
```

### 4.2 Traditional Grid

```
┌──────────────────────────────────┐
│ ◄ Chapter 12: Finale       ⋮     │
├──────────────────────────────────┤
│                                  │
│ ┌──────────┐ ┌──────────┐       │
│ │ [Panel 1]│ │ [Panel 2]│       │
│ │          │ │          │       │
│ └──────────┘ └──────────┘       │
│                                  │
│ ┌──────────┐ ┌──────────┐       │
│ │ [Panel 3]│ │ [Panel 4]│       │
│ │          │ │          │       │
│ └──────────┘ └──────────┘       │
│                                  │
│ ┌──────────┐ ┌──────────┐       │
│ │ [Panel 5]│ │ [Panel 6]│       │
│ │          │ │          │       │
│ └──────────┘ └──────────┘       │
│                                  │
│ Progress: ███████░░░░ 68%        │
│ [Previous] [Fullscreen] [Next]   │
│                                  │
└──────────────────────────────────┘
```

---

## 5. Audiobook Player

### 5.1 Playback Interface

```
┌──────────────────────────────────┐
│ ◄ Echoes of Tomorrow       ⋮     │
├──────────────────────────────────┤
│                                  │
│      [AUDIOBOOK COVER]           │
│      (Large display)             │
│                                  │
│ Chapter 5: Arrival               │
│ Narrated by Jane Smith           │
│                                  │
│ Progress: ███░░░░░░░░░░░░       │
│ 12:34 / 34:56                    │
│                                  │
│ [◀◀] [⏮] [▶] [⏸] [⏭] [▶▶]      │
│ -30s Skip Start Pause Skip +30s   │
│                                  │
│ Playback Speed: 1.0x  [1.25x]    │
│                                  │
│ [🔖] Bookmark                    │
│ [💬] Add Note                    │
│ [📚] Table of Contents           │
│                                  │
│ ≡ More Options                   │
│                                  │
│ ──────────────────────────────   │
│ Chapters (Chapter 5 Playing)     │
│ Chapter 4: Awakening    [✓]      │
│ ► Chapter 5: Arrival    [12:34]  │
│   Next: Chapter 6                │
│                                  │
└──────────────────────────────────┘
```

### 5.2 Chapters & Navigation

```
┌──────────────────────────────────┐
│ 📚 Echoes of Tomorrow            │
│ Table of Contents            ✕   │
├──────────────────────────────────┤
│                                  │
│ ✓ Prologue             0:00      │
│ ✓ Chapter 1           5:12       │
│ ✓ Chapter 2          10:45       │
│ ✓ Chapter 3          16:32       │
│ ✓ Chapter 4          24:10       │
│ ► Chapter 5          32:18       │
│   [PLAYING NOW]                  │
│ ○ Chapter 6 (locked) Preview     │
│ ○ Epilogue (locked)  Preview     │
│                                  │
│              [SUBSCRIBE TO UNLOCK]│
│                                  │
│ Total Duration: 12h 45min        │
│ Est. Remaining: 3h 22min (1.0x)  │
│                                  │
└──────────────────────────────────┘
```

---

## 6. Analytics & Reading Stats

### 6.1 User Reading Dashboard

```
┌──────────────────────────────────┐
│ 📖 My Reading Dashboard          │
├──────────────────────────────────┤
│                                  │
│ This Month                       │
│ 📖 Books Read: 3                 │
│ ⏱️ Total Time: 18h 45min         │
│ 📝 Total Words: 245,000          │
│ 🔖 Bookmarks Created: 24         │
│                                  │
├──────────────────────────────────┤
│ Currently Reading                │
│                                  │
│ 1. The Last Journey              │
│    Progress: 68%  Next: Ch. 12   │
│    Last read: 2 hours ago        │
│    [CONTINUE]                    │
│                                  │
│ 2. The Mysterious Island         │
│    Progress: 42%  Waiting: Ch. 6 │
│    Updates: Mondays              │
│    [SUBSCRIBE]                   │
│                                  │
│ 3. Pixel Dreams (Comic)          │
│    Progress: Episode 5/20        │
│    Last read: Yesterday          │
│    [CONTINUE]                    │
│                                  │
├──────────────────────────────────┤
│ Reading History                  │
│ [VIEW ALL]                       │
│                                  │
│ Oct 29 - The Last Journey        │
│ Oct 28 - Pixel Dreams            │
│ Oct 27 - The Mysterious Island   │
│                                  │
└──────────────────────────────────┘
```

### 6.2 Author Analytics

```
┌──────────────────────────────────┐
│ 📊 Story Analytics               │
│ The Mysterious Island            │
├──────────────────────────────────┤
│                                  │
│ Reader Engagement                │
│ Total Reads: 5,247               │
│ Avg Completion: 68%              │
│ Avg Time/Chapter: 14 min         │
│ Peak Readers: 348 (Ch. 5)        │
│                                  │
│ Completion by Chapter            │
│ Ch.1 ███████████████ 100%        │
│ Ch.2 ██████████░░░░  85%         │
│ Ch.3 ████████░░░░░░  72%         │
│ Ch.4 ██████░░░░░░░░  54%         │
│ Ch.5 ████░░░░░░░░░░  42%         │
│                                  │
│ Geographic Distribution          │
│ 🇺🇸 USA: 2,145 (41%)            │
│ 🇬🇧 UK: 892 (17%)              │
│ 🇨🇦 Canada: 645 (12%)          │
│ Other: 1,565 (30%)               │
│                                  │
│ Earnings This Month              │
│ Chapter Subscriptions: $487      │
│ Outright Purchases: $213        │
│ Total: $700                      │
│                                  │
└──────────────────────────────────┘
```

---

## 7. Publishing Workflow (Author Side)

### 7.1 Upload New Work

```
┌──────────────────────────────────┐
│ ➕ Create New Work               │
├──────────────────────────────────┤
│                                  │
│ [1] Choose Content Type          │
│ ○ Book (Complete)               │
│ ○ Series (Ongoing)              │
│ ○ Short Story                   │
│ ○ Comic/Webtoon                │
│ ○ Audiobook                     │
│ ○ Podcast                       │
│ [NEXT]                           │
│                                  │
│ [2] Upload Cover & Metadata      │
│ Cover: [Choose File]             │
│ Title: [The Last Journey]        │
│ Description: [textarea]          │
│ Author: Sarah Chen               │
│ Language: English                │
│ Tags: [fantasy, adventure]       │
│ [NEXT]                           │
│                                  │
│ [3] Upload Content               │
│ For Book:                        │
│ ○ Upload File (.txt, .pdf)      │
│ ○ Paste Text                    │
│ ○ Import from Drive             │
│ [Auto-split into chapters]       │
│ [NEXT]                           │
│                                  │
│ [4] Set Pricing & Access         │
│ Price: [$4.99]                   │
│ Access: [Free / Paid]            │
│ Subscription: [Toggle]           │
│ [NEXT]                           │
│                                  │
│ [5] Review & Publish             │
│ Preview: [Show]                  │
│ [PUBLISH] [SCHEDULE]             │
│                                  │
└──────────────────────────────────┘
```

### 7.2 Schedule Releases

```
┌──────────────────────────────────┐
│ 🗓️ Schedule Releases            │
│ The Mysterious Island            │
├──────────────────────────────────┤
│                                  │
│ Release Schedule Type:           │
│ ○ Custom Dates                   │
│ ● Weekly                         │
│ ○ Bi-weekly                      │
│ ○ Monthly                        │
│                                  │
│ Start Date: [Oct 1, 2024]        │
│ Time: [10:00 AM] (UTC-5)         │
│ Day: [Monday] ✓                  │
│                                  │
│ Chapters to Schedule:            │
│ [12 chapters total]              │
│                                  │
│ Auto-Generate Schedule           │
│ Chapter 1 → Oct 1 10:00 AM      │
│ Chapter 2 → Oct 8 10:00 AM      │
│ Chapter 3 → Oct 15 10:00 AM     │
│ ... (9 more)                     │
│                                  │
│          [CONFIRM & SCHEDULE]    │
│                                  │
│ Notifications:                   │
│ ☑ Email author on release        │
│ ☑ Notify subscribers             │
│                                  │
└──────────────────────────────────┘
```

---

## Summary

**Key UI Principles for Written Content**:

1. **Clear Content Type Identification**: Icons/labels for book 📖, comic 📺, audio 🎧
2. **Reading Time Transparency**: Show estimated time before reading starts
3. **Progress Tracking**: Visual indicators for series progress and reading completion
4. **Reading Customization**: Font, size, colors, line spacing for text comfort
5. **Engagement Tools**: Bookmarks, notes, highlights, sharing
6. **Author Attribution**: Clear author info, following, messaging
7. **Analytics Visibility**: For both readers and authors, actionable insights

**Differentiation from Visual Art**:
- No cover image-only focus; content preview/excerpt important
- Reading time > dimensions
- Progress bars for ongoing series prominent
- Release schedules clearly displayed
- Reading session history tracked
- Content-specific readers (text, comic, audio)
