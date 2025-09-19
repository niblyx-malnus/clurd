# Frequently Observed Oversights (FOO)

A collection of common mistakes Claude makes when working with Urbit, to help avoid repeating them.

## Path and Desk Notation

### ❌ Forgetting desk notation for threads
**Mistake**: Running threads without specifying desk when not in %base

**Reality**: Threads require explicit desk specification unless using %base

**Correct**: Use `-desk!thread-name` or ensure you're in %base desk context

### ❌ Incorrect Hoon comment formatting
**Mistake**: Writing comments like:
```hoon
::
:: comment
++  gate
```
**Reality**: Comments should be followed by a blank comment line
**Correct**: 
```hoon
:: comment
::
++  gate
```

## Import Patterns

### ❌ Using wildcard imports (*) 
**Mistake**: Importing with `/-  *bitcoin` or multiple wildcards like `/-  *bitcoin, *wallet`

**Reality**: Wildcard imports pollute the namespace and cause confusion about where names come from

**Correct**: Use explicit aliases like `/-  btc=bitcoin` or even single letters `/-  b=bitcoin`

## Environment Assumptions

### ❌ Assuming specific ship configurations
**Mistake**: Expecting certain apps/desks to be installed or running

**Reality**: Ship configurations vary, %base is the only reliable constant

**Correct**: Always specify which desk/app is required, provide installation steps

### ❌ Not accounting for working directory context
**Mistake**: Giving paths without considering current `=dir` location

**Reality**: Current directory affects relative path behavior
**Correct**: Use absolute paths with substitution or explicitly reset with `=dir`

---

*This document grows as we encounter new common mistakes. Add entries when patterns emerge.*
