# bash-2dd

The TDD and BDD test framework for bash that no one asked for!

Other test frameworks for bash are too complicated.

- For TDD, each file is executed and the exit code is reported as pass or fail. Nothing fancy.
- For BDD, each "Scenario" is run in a separate subprocess. Tell `2dd` what function to run for each statement in the feature file using a pattern matched by the `=~` operator.

## Installation

Clone the repository.

```
git clone https://github.com/reidgould/bash-2dd.git "$HOME/.local/share/bash-2dd"
```

Add the `bin` folder to your `PATH`. Add the line below to your `.bashrc` to make it load for every session.

```
export "$HOME/.local/share/bash-2dd/bin/:$PATH"
```

## Invocation

Run only TDD files with:

```
tdd
```

Run only BDD files with:

```
bdd
```

Run both TDD and BDD files with:

```
2dd
```

## Examples

Check out the `test` directory in the repository for examples of how to use `2dd`.

If you're not sure where to start, try one of these.

### TDD Example

TDD files are any bash script. The exit code `0` is reported as a pass, any other code is reported as a fail. Check out this file: [test/race/a.test.bash](test/race/a.test.bash)

Run the commands:

```
cd test/simpleBdd
2dd
```

The output looks something like below. It has color in your terminal!

```
# Tests
✓ pass b.test.bash
✓ pass z.test.bash
✓ pass a.test.bash

# Summary
To see test logs, "cat" files in directory:
/tmp/vscode/2dd/run/1754102960.NWx/logs/stdOutErr

3 tests ran. 3 passed. 0 failed. 0 skipped.
```

### BDD Example

Run the commands:

```
cd test/simpleBdd
2dd
```

Check out the files for this test:

- [test/simpleBdd/simpleBdd.feature](test/simpleBdd/simpleBdd.feature)
- [test/simpleBdd/simpleBdd.testSteps.bash](test/simpleBdd/simpleBdd.testSteps.bash)

A step implementation looks like this:

```
Given 'setup for (all tests|test [ABC]) is ready.' setup_ready
function setup_ready {
  echo "Completed setup steps for $1"
}
```

The output looks something like below. It has color in your terminal!

```
# Tests
✓ pass simpleBdd.feature (Scenario 0)
  Background:
  ✓ pass Given setup for all tests is ready.
  Scenario: Test A is run.
  ✓ pass Given setup for test A is ready.
  ✓ pass When test A runs.
  ✓ pass Then test A passes assertions.
✓ pass simpleBdd.feature (Scenario 1)
  Background:
  ✓ pass Given setup for all tests is ready.
  Scenario: Test B is run.
  ✓ pass Given setup for test B is ready.
  ✓ pass When test B runs.
  ✓ pass Then test B passes assertions.
- skip simpleBdd.feature (Scenario 2)
✗ fail simpleBdd.feature (Scenario 3)
  Background:
  ✓ pass Given setup for all tests is ready.
  Scenario: Test with error is run.
  ✓ pass Given setup for test C is ready.
  ✗ fail When test with error runs.
  - skip Then test C passes assertions.
✓ pass tagExample.feature (Scenario 0)
  Scenario: Reserving a single book
  ✓ pass Then it works.
✓ pass tagExample.feature (Scenario 1)
  Scenario: Reserving a single book
  ✓ pass Then it works.

# Summary
To see test logs, "cat" files in directory:
/tmp/<your-user-name>/2dd/run/<id-number>/logs/stdOutErr

6 tests ran. 4 passed. 1 failed. 1 skipped.
```

## Test File Discovery

### Work Directory

`2dd` finds files by searching recursively from the current work directory. Support for giving the root path or individual file names is planned to be added in the future.

### File Names

TDD test files are found using pattern `*.test.bash`

BDD feature files are found using pattern `*.feature`

BDD step definition files are found using pattern `*.test-steps.bash` and `*.testSteps.bash`

## Tags

Use arguments like `--tag myTag` to run only tests that have a matching tag, and skip all others. More capable tag matching is desired, but not yet implemented.

BDD feature files are tagged as [described in the docs](https://cucumber.io/blog/bdd/gherkin-rules/#consistency-is-coming).

TDD files must have a comment at the top of the file before any non-comment or non-blank line that contains only tags with a leading `@` character, like so:

```
#! /usr/bin/bash
# @myTag @myOtherTag
echo "Do any scripty things you like after the tags."
```

### Special tags `@skip` and `@only`

Any test with the `@skip` flag is not run and is reported as skipped.

If any test is found with the `@only` tag, no other tests will be run except those that have the tag.

## Parallel Jobs

Runs 3 jobs by default. Specify the number using an argument like `--jobs 5`.

If you use `--jobs 1`, it does not background the test runs.

## Interactive

I'll fess up, I don't always have a plan to test scripts that need input.

Give the `--interactive` flag to connect stdin, stdout, and stderr to the terminal so you can give input during the run. (This is an alias for `--jobs 1 --verbose`)

This probably won't work for software that moves the cursor or uses the alternate screen. It uses some redirection and isn't _directly_ connected to the pty, so your mileage may vary.

## Test Logs

### Standard Logs Available in `tmp` Directory

The summary of each run is printed to the console and includes the path to a directory which contains files corresponding to each test and contains the content printed to stderr and stdout. It has a pattern like this:
`/tmp/<your-user-name>/2dd/run/<id-number>/logs/stdOutErr`.

If your test prints terminal control codes, like color, they will be contained in these files.

The easiest way to view them is to use `cat` to print them to the terminal.

`bat` is software similar to cat that you can install that shows a nice display if you pass it all the names like `bat <path>/*`. `bat` is not usually installed by default, [installation options here](https://github.com/sharkdp/bat?tab=readme-ov-file#installation).

You can also view files containing colored output in the `less` pager by giving the `-R` option like `less -R <file>`.

### Custom Test Logs on Console Output

You can print additional logs to the console, instead of capturing them in the usual log file, by printing to the file descriptor number in environment variable `logTestFD`. For example: `echo "hello console" >&$logTestFD`.

There are helper functions that provide this redirection and formating which you can use by sourcing the `dependencies/05-log.bash` file from this repository.

- `logTest`
- `logPass`
- `logFail`
- `logSkip`

Example content of `myTestFile.test.bash`:

```
#! /usr/bin/bash
source "$HOME/.local/share/2dd/dependencies/05-log.bash
logPass My Custom Sub Test
```

Example console output:

```
❯ 2dd
# Tests
✓ pass myTestFile.test.bash
  ✓ pass My Custom Sub Test

# Summary
To see test logs, "cat" files in directory:
/tmp/<your-user-name>/2dd/run/<id-number>/logs/stdOutErr

1 tests ran. 1 passed. 0 failed. 0 skipped.
```

## BDD Support Details

Supports most features described in the [Gherkin Reference](https://cucumber.io/docs/gherkin/reference/).

Supports only one "Feature" statement per `.feature` file.

"Background" statements must come before "Scenario" or "Example" statements.

Each "Scenario" is run in a separate subprocess.

Passes pattern matches as arguments to the step functions using `BASH_REMATCH` internally.

Support for Scenario Outlines, "Examples" keyword and Data Tables is planned, but not yet implemented.

Does not support Doc Strings. Support is not planned.
