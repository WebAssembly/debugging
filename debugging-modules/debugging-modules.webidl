typedef unsigned long WasmBreakpointId;
typedef unsigned long WasmCodeOffset;
typedef unsigned long SourceBreakpointId;
typedef unsigned long SourceLine;
typedef unsigned long SourceColumn;
typedef DOMString SourceFilename;
typedef DOMString SourceFunctionName;

/**
 * The raw debugging APIs for a Wasm module.
 *
 * Implementations of this interface are provided by the Wasm engine, and called
 * by user-provided implementations of `SourceDebugger`.
 */
interface WasmDebugger {
    /**
     * Set a breakpoint at the instruction at the given offset into the Code
     * section.
     *
     * Execution should be paused when reaching this offset, but before
     * evaluating its associated instruction.
     */
    WasmBreakpointId? setBreakpoint(WasmCodeOffset offset);

    /**
     * Clear a breakpoint that was previously set.
     */
    void clearBreakpoint(WasmBreakpointId breakpoint);

    /**
     * Get the contents of a custom section, if it exists in this module.
     *
     * `SourceDebugger` implementations may use this method to read encoded line
     * tables or other debug information from the Wasm module.
     */
    ArrayBuffer? getCustomSection(USVString customSectionName);
};

/**
 * Options provided by the debugger when requesting that a `SourceDebugger` set
 * a breakpoint.
 */
dictionary SourceBreakpointOptions {
    required SourceFilename filename;
    required SourceLine line;
    SourceLine column;
};

/**
 * Information about a Wasm breakpoint that has been hit.
 */
dictionary WasmBreakInfo {
    required WasmBreakpointId breakpoint;
};

/**
 * The kind of source-level action to take after hitting a Wasm breakpoint.
 */
enum SourceBreakResultKind {
    /**
     * Continue execution and ignore the breakpoint.
     */
    "Continue",
    /**
     * Pause execution because we hit a source-level breakpoint or did a step.
     */
    "Pause",
};

/**
 * How a Wasm breakpoint in the debuggee should be handled.
 */
dictionary SourceBreakResult {
    /**
     * The kind of action that should be taken: should the debuggee pause at a
     * source-level breakpoint or continue execution?
     */
    required SourceBreakResultKind kind;

    /**
     * If the `kind` is `"Pause"`, this is the source-level breakpoint that the
     * debuggee is paused at, if we hit a breakpoint.
     */
    SourceBreakpointId breakpoint;

    /**
     * If the `kind` is `"Pause"`, this is the source location where execution
     * is paused at.
     */
    SourceLocation location;
};

/**
 * What kind of step should be taken.
 */
enum SourceStepKind {
    /**
     * If currently paused before a function call, continue to the first
     * expression of that function. Otherwise, continue execution until the next
     * line of code.
     */
    "Into",
    /**
     * Continue execution until the next line of code.
     */
    "Over",
    /**
     * Continue execution until the function returns.
     */
    "Out",
};

dictionary SourceStepOptions {
    required SourceStepKind kind;
};

/**
 * A range within a source file.
 *
 * Inclusive of `startLine:startColumn`, and exclusive of `endLine:endColumn`.
 */
dictionary SourceRange {
    required SourceFilename filename;
    SourceFunctionName function;

    required SourceLine startLine;
    required SourceColumn startColumn;

    required SourceLine endLine;
    required SourceColumn endColumn;
};

/**
 * A location inside some source text.
 */
dictionary SourceLocation {
    required SourceFilename filename;
    required SourceLine line;
    SourceColumn column;
};

/**
 * A range of instructions within a Wasm module's Code section.
 *
 * Inclusive of `start`, and exclusive of `end`.
 */
dictionary WasmCodeRange {
    required WasmCodeOffset start;
    required WasmCodeOffset end;
};

/**
 * Source-level debugging APIs for a Wasm module.
 *
 * Debugging modules provide an implementation of this interface, wrapping and
 * translating the given `WasmDebugger`'s raw Wasm-level debugging APIs into
 * source-level debugging APIs which are used by various developer tools
 * (debuggers, profilers, etc).
 */
[Constructor(WasmDebugger)]
interface SourceDebugger {
    /**
     * Set a source-level breakpoint at the given source position.
     *
     * Execution should be paused when reaching this location, but before
     * evaluating its associated code.
     */
    SourceBreakpointId? setBreakpoint(SourceBreakpointOptions options);

    /**
     * Clear a source-level breakpoint that was previously set.
     */
    void clearBreakpoint(SourceBreakpointId breakpoint);

    /**
     * This method will be called whenever the debuggee hits a Wasm
     * breakpoint. This allows the `SourceDebugger` to translate Wasm-level
     * breaks into source-level breaks.
     */
    SourceBreakResult onBreak(WasmBreakInfo);

    /**
     * This method is called when the debuggee module is paused to step into,
     * over, or out of a function.
     *
     * `SourceDebugger` implementations should set Wasm breakpoint(s) where
     * execution should pause after taking the requested step.
     */
    void onStep(SourceStepOptions options);

    /**
     * Get the source range(s) for the given code offset, if any.
     *
     * Note that various code transformations (e.g. common subexpression
     * elinimation) may result in an offset mapping to multiple source ranges.
     *
     * Note that an offset may also not map to any source range, for example if
     * debug information is unavailable for a linked object file that
     * contributed to this Wasm module's compilation.
     */
    Sequence<SourceRange> getSourceRanges(WasmCodeOffset offset);

    /**
     * Get the code offset(s) for the given source location, if any.
     *
     * Note that a source location may map to multiple code ranges, for example
     * if one of a location's subexpressions has been hoisted out of a loop.
     *
     * Note that a source location might not map to any code range. A trivial
     * example is a source location within a comment in the source text. Another
     * example is an expression that was dead code eliminated.
     */
    Sequence<WasmCodeRange> getWasmCodeRanges(SourceLocation location);

    /**
     * Get a list of the source files that this Wasm module was compiled from.
     */
    Sequence<SourceFilename> listSources();

    /**
     * Get the source text for the given source file.
     */
    SourceText? getSourceText(SourceFilename source);
};
