# File Renamer

File Renamer is a native macOS utility for batch-renaming files with a simple find-and-replace workflow. Drop files into the window, preview the new names, then rename every matching file in one action.

## Features

- Drag and drop files into the app
- Choose multiple files with the system file picker
- Preview original names and new names before renaming
- Highlight matched text and replacement text
- Match text with or without case sensitivity
- Use regular expressions for more advanced replacements
- Shows file icons, file sizes, match counts, success messages, and rename errors

## Requirements

- macOS
- Xcode with SwiftUI support
- The project currently targets macOS 26.4 in Xcode

If your installed Xcode does not include that SDK, open the project settings and lower the macOS deployment target to a version available on your machine.

## Getting Started

1. Open `File Renamer.xcodeproj` in Xcode.
2. Select the `File Renamer` scheme.
3. Choose a macOS run destination.
4. Press `Run`.

## How To Use

1. Drag files into the drop area, or click `choose files...`.
2. Enter the text to find in the `Find` field.
3. Enter the replacement text in the `Replace With` field.
4. Turn on `Match case` if the search should be case-sensitive.
5. Turn on `Use regular expression` if the find value should be treated as a regex pattern.
6. Review the preview table.
7. Click `Rename` to apply the changes.

The app only renames files that have a changed preview name. Files with no match are left untouched.

## Regular Expressions

When `Use regular expression` is enabled, the find field is interpreted as an `NSRegularExpression` pattern. The replacement field is passed through as the replacement template, so capture groups can be referenced with standard Foundation replacement syntax such as `$1`.

Invalid regex patterns are ignored in the preview and do not rename files.

## Project Structure

```text
File Renamer/
├── File Renamer.xcodeproj
└── File Renamer/
    ├── Assets.xcassets
    ├── ContentView.swift
    └── File_RenamerApp.swift
```

- `File_RenamerApp.swift` defines the SwiftUI app entry point and default window size.
- `ContentView.swift` contains the file picker, drag-and-drop handling, preview table, replacement logic, and rename action.
- `Assets.xcassets` contains app icon and accent color assets.

## Notes

- Directories cannot be selected from the file picker; the app is designed for files.
- Rename operations happen in place, in each file's existing folder.
- If a destination filename already exists or the system blocks the move, the app shows an error for that file.
- After a successful rename, the selected file list and search fields are cleared.
