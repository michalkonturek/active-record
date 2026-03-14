# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A lightweight Active Record implementation for Swift Data. Swift package library (not an executable).

## Build & Test Commands

- **Build:** `swift build`
- **Test all:** `swift test`
- **Test single:** `swift test --filter active-record-tests.TestClassName/testMethodName`

## Architecture

- **Swift tools version:** 6.2 (strict concurrency by default)
- **Library target:** `active-record` (Sources/active-record/)
- **Test target:** `active-record-tests` (Tests/active-record-tests/) — uses Swift Testing framework (`import Testing`, `@Test` macro), not XCTest
- **Module import name:** `active_record` (hyphens become underscores in Swift module names)
