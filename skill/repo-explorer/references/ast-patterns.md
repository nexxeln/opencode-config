# Common AST-grep Patterns

Reference for structural code search patterns. Use with `repo-ast.sh`.

## Pattern Syntax

- `$NAME` - Single metavariable (matches exactly one AST node)
- `$$ARGS` - Multi metavariable (matches zero or more nodes)
- `$_` - Anonymous metavariable (matches but doesn't capture)

## JavaScript/TypeScript Patterns

### Functions
```
# Named function
function $NAME($$ARGS) { $$BODY }

# Arrow function
const $NAME = ($$ARGS) => $$BODY

# Async function
async function $NAME($$ARGS) { $$BODY }

# Method definition
$NAME($$ARGS) { $$BODY }
```

### React Patterns
```
# Function component
function $NAME($$_) { return $$_ }

# useState hook
const [$STATE, $SETTER] = useState($INIT)

# useEffect hook
useEffect(() => { $$BODY }, [$DEPS])

# JSX element
<$TAG $$ATTRS>$$CHILDREN</$TAG>

# JSX self-closing
<$TAG $$ATTRS />
```

### Common Patterns
```
# Console statements
console.log($$ARGS)
console.$METHOD($$ARGS)

# Import statement
import $NAME from '$PATH'
import { $$NAMES } from '$PATH'

# Export
export const $NAME = $VALUE
export function $NAME($$_) { $$_ }
export default $EXPR

# Try-catch
try { $$TRY } catch ($ERR) { $$CATCH }

# If statement
if ($COND) { $$BODY }

# Ternary
$COND ? $THEN : $ELSE
```

### Class Patterns
```
# Class definition
class $NAME { $$BODY }

# Class with extends
class $NAME extends $PARENT { $$BODY }

# Constructor
constructor($$ARGS) { $$BODY }

# Class method
$NAME($$ARGS) { $$BODY }
```

## Python Patterns

```
# Function definition
def $NAME($$ARGS): $$BODY

# Async function
async def $NAME($$ARGS): $$BODY

# Class definition
class $NAME: $$BODY

# Class with inheritance
class $NAME($PARENT): $$BODY

# Decorator
@$DECORATOR
def $NAME($$_): $$_

# With statement
with $EXPR as $VAR: $$BODY

# Try-except
try: $$TRY
except $EXC: $$CATCH

# List comprehension
[$EXPR for $VAR in $ITER]

# Import
import $MODULE
from $MODULE import $NAME
```

## Go Patterns

```
# Function
func $NAME($$ARGS) $RET { $$BODY }

# Method
func ($RECV $TYPE) $NAME($$ARGS) $RET { $$BODY }

# Struct
type $NAME struct { $$FIELDS }

# Interface
type $NAME interface { $$METHODS }

# Error handling
if err != nil { $$BODY }

# Goroutine
go $FUNC($$ARGS)

# Channel send
$CHAN <- $VALUE

# Channel receive
$VAR := <-$CHAN
```

## Rust Patterns

```
# Function
fn $NAME($$ARGS) -> $RET { $$BODY }

# Impl block
impl $TYPE { $$METHODS }

# Trait impl
impl $TRAIT for $TYPE { $$METHODS }

# Struct
struct $NAME { $$FIELDS }

# Enum
enum $NAME { $$VARIANTS }

# Match expression
match $EXPR { $$ARMS }

# Result handling
$EXPR?

# Unwrap
$EXPR.unwrap()
```

## Tips

1. Start broad, then narrow down:
   - `function $_($$_) { $$_ }` finds all functions
   - Then add specifics like async, name patterns

2. Use `$_` for parts you don't care about:
   - `console.$_($$_)` matches any console method

3. Combine with `--lang` for accuracy:
   - `repo-ast.sh owner/repo 'async function' --lang ts`

4. Multi-metavars `$$` are greedy:
   - They match as much as possible within the grammar
