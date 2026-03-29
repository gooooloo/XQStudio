# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

XQStudio 1.63 is a Chinese Chess (象棋, Xiangqi) game record editor/viewer, written in **Delphi 5.0** (Object Pascal) by DONG Shiwei (董世伟), circa 1998-2008. Licensed under BSD 3-Clause.

There is also a `JavaXQ/` directory containing a Java Applet (`JavaXQ.java`) that renders a simplified xiangqi board — it is standalone and unrelated to the Delphi build.

## Build

- **IDE**: Borland Delphi 5.0 (Windows-only)
- **Project file**: `Src/XQStudio.dpr`
- **Compiler config**: `Src/XQStudio.cfg` and `Src/XQStudio.dof`
- No Makefile or command-line build script exists; compilation is done via the Delphi IDE
- There are no automated tests

## Architecture

The Delphi source in `Src/` is organized as follows:

| Unit | Role |
|------|------|
| `XQStudio.dpr` | Program entry point; creates main form and application forms |
| `XQMain.pas` | Main MDI form (`TfrmMain`) — menus, toolbar, application-level actions |
| `XQDataT.pas` | Core data types and constants (version info, board representation, piece constants) |
| `XQPNode.pas` | `dTXQPlayNode` — tree node for game moves; child/sibling tree structure for move variations |
| `XQSystem.pas` | Game system logic — move validation, board state management |
| `XQTable.pas` | Board table form (`TfrmXQTable`) — visual board rendering and interaction |
| `XQView.pas` | Board view rendering utilities |
| `XQFileRW.pas` | File I/O — reads/writes `.xqf` format (binary, with XOR-based encoding; signature `$5158` = "XQ") |
| `XQFileP.pas` | File properties dialog |
| `XQRecLBX.pas` | Record listbox — manages list of game records |
| `XQVarLBX.pas` | Variation listbox — displays move variations/branches |
| `XQSearch.pas` | Search dialog for finding games/positions |
| `XQWizard.pas` | New game wizard |
| `XQAbout.pas` | About dialog |
| `XQReadme.pas` | Readme display form |
| `XQTipsDlg.pas` | Tips dialog |
| `XQMultiInst.pas` | Multi-instance prevention (uses GlobalAtom) |
| `dDelphiS.pas` | Utility/helper library (generic Delphi supplements) |

### Key data flow

- Game records are stored in `.xqf` binary format; `XQFileRW` handles serialization with XOR masking
- Move history is a tree (`dTXQPlayNode`) with child (next move) and sibling (variation) pointers
- `XQSystem` validates moves against xiangqi rules and maintains board state (a 10x9 array)
- `XQTable` renders the board using bitmaps from `Bitmap/`

## File Encoding

Source files contain **GB2312/GB18030** encoded Chinese characters in comments and string literals.
