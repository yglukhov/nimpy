# nimpy [![Build Status](https://travis-ci.org/yglukhov/nimpy.svg?branch=master)](https://travis-ci.org/yglukhov/nimpy)

Native language integration with Python has never been easier!

## Implementing python module in nim
```nim
# mymodule.nim - file name should match the module name you're going to import from python
import nimpy

proc greet(name: string): string {.exportpy.} =
    return "Hello, " & name & "!"
```

```
# Compile on Windows:
nim c --threads:on --app:lib --out:mymodule.pyd mymodule
# Compile on everything else:
nim c --threads:on --app:lib --out:mymodule.so mymodule
```

```py
# test.py
import mymodule
assert mymodule.greet("world") == "Hello, world!"
assert mymodule.greet(name="world") == "Hello, world!"
```

## Calling python from nim
```nim
import nimpy
let os = pyImport("os")
echo "Current dir is: ", os.getcwd().to(string)

# sum(range(1, 5))
let py = pyBuiltinsModule()
let s = py.sum(py.range(0, 5)).to(int)
assert s == 10
```
Note: here nimpy relies on your local python installation.

## Misc
The library is designed with ABI compatibility in mind. That is
the compiled module doesn't depend on particular Python version, it should
properly work with any. The C API symbols are loaded in runtime from whichever
process has launched your module.


## Publish to PYPI

<details>
  <summary> Tutorial to Publish to PYPI </summary>

This tutorial assumes you already have a `setup.py` on your Repo,
check Python Documentation if you dont know how to make a `setup.py`.

You must have a valid active PyPI username and password to upload to PyPI,
if you do not have one go to https://pypi.org/account/register and register yourself,
if you do have one go to https://pypi.org/account/login and login to check if its working.

Go to `https://github.com/USER/REPO/settings/actions`,
where USER is your GitHub username, and REPO is your repo,
check that GitHub Actions must be **Enabled**.

Go to `https://github.com/USER/REPO/settings/secrets/new`,
where USER is your GitHub username, and REPO is your repo.

Create 2 new Secrets named `PYPI_USERNAME` and `PYPI_PASSWORD`,
where PYPI_USERNAME is your PyPI username, and PYPI_PASSWORD is your PyPI password,
Secrets wont need quotes, dont worry both will be Encrypted, not visible from the web, nor visible from Forks.

On your Repo create a new file `/.github/workflows/nimpy_pypi_upload.yml`,
create the folders if needed, create the file if needed, and paste the whole following content:

```yaml
name: Upload to PYPI

on:
  release:
    types: [created]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v1
    - uses: actions/setup-python@v1

    - name: Set Global Environment Variables
      uses: allenevans/set-env@v1.0.0
      with:
        CHOOSENIM_CHOOSE_VERSION: "1.0.4"
        CHOOSENIM_NO_ANALYTICS: 1
        TWINE_NON_INTERACTIVE: 1
        TWINE_USERNAME: ${{ secrets.PYPI_USERNAME }}   # https://github.com/USER/REPO/settings/secrets/new
        TWINE_PASSWORD: ${{ secrets.PYPI_PASSWORD }}
        MAIN_MODULE: "src/main.nim"
        #TWINE_REPOSITORY_URL: "https://test.pypi.org/legacy/"  # Upload to PYPI Testing fake server.
        #TWINE_REPOSITORY: "https://test.pypi.org/legacy/"

    - name: Update Python PIP
      run: pip3 install --upgrade --disable-pip-version-check pip setuptools twine

    - name: Cache choosenim
      id: cache-choosenim
      uses: actions/cache@v1
      with:
        path: ~/.choosenim
        key: ${{ runner.os }}-choosenim-$CHOOSENIM_CHOOSE_VERSION

    - name: Cache nimble
      id: cache-nimble
      uses: actions/cache@v1
      with:
        path: ~/.nimble
        key: ${{ runner.os }}-nimble-$CHOOSENIM_CHOOSE_VERSION

    - name: Install Nim via Choosenim
      if: steps.cache-choosenim.outputs.cache-hit != 'true' || steps.cache-nimble.outputs.cache-hit != 'true'
      run: |
        curl https://nim-lang.org/choosenim/init.sh -sSf > init.sh
        sh init.sh -y

    - name: Nimble Refresh
      run: |
        export PATH=$HOME/.nimble/bin:$PATH
        nimble -y refresh

    - name: Nimble Install dependencies
      run: |
        export PATH=$HOME/.nimble/bin:$PATH
        nimble -y install nimpy

    - name: Prepare Files
      run: |
        mkdir --verbose --parents dist/
        rm --verbose --force --recursive *.c *.h *.so *.pyd *.egg-info/ dist/*.zip
        cp --verbose --force ~/.choosenim/toolchains/nim-$CHOOSENIM_CHOOSE_VERSION/lib/nimbase.h nimbase.h

    - name: Compile to C
      run: |
        export PATH=$HOME/.nimble/bin:$PATH
        nim compileToC --compileOnly -d:release -d:danger -d:ssl --threads:on --app:lib --opt:speed --gc:markAndSweep --nimcache:. $MAIN_MODULE

    - name: Publish to PYPI
      run: |
        python3 setup.py --verbose sdist --formats=zip
        rm --verbose --force --recursive *.c *.h *.so *.pyd *.egg-info/
        twine upload --verbose --disable-progress-bar dist/*.zip

```

Edit `CHOOSENIM_CHOOSE_VERSION` to the version you choose or the latest.
Edit `MAIN_MODULE: "src/main.nim"` to your main module `.nim` file.

If you want to upload to the Testing fake PyPI Server instead of the real one, uncomment the lines:

```yaml
TWINE_REPOSITORY_URL: "https://test.pypi.org/legacy/"  # Upload to PYPI Testing fake server.
TWINE_REPOSITORY: "https://test.pypi.org/legacy/"
```

Commit and Push the YAML to GitHub.

Go to `https://github.com/USER/REPO/releases/new`,
where USER is your GitHub username, and REPO is your repo,
create a new Release to trigger the new GitHub Action of the YAML,
Editing an existing Release wont work, so the Release must be a new one.

Wait for the GitHub Action to complete, you can check the progress at `https://github.com/USER/REPO/actions`,
if the GitHub Actions is sucessful then you should have your project uploaded to PyPI.

Remember that PyPI wont allow to Re-upload the same file even if you delete it,
so if you want to overwrite the file uploaded to PyPI you must bump version up.

From now on, everytime you make a new Release, it will be automatically uploaded to PYPI.

</details>


## Troubleshooting, Q&A
<details>
<summary> <b>Question:</b>

Importing the compiled module from Python fails with `ImportError: dynamic module does not define module export function ...`
</summary>

  Make sure that the module you're importing from Python has exactly the same name as the `nim` file which the module is implemented in.
</details>

<details>
<summary> <b>Question:</b>

Nim strings are converted to Python `bytes` instead of `string`
</summary>

  nimpy converts Nim strings to Python strings usually, but since Nim strings are encoding agnostic and may contain invalid utf8 sequences, nimpy will fallback to Python `bytes` in such cases.
</details>

<details>
<summary> <b>Question:</b>

Is there any numpy compatibility?
</summary>

  nimpy allows manipulating numpy objects just how you would do it in Python,
however it not much more efficient. To get the maximum performance nimpy
exposes [Buffer protocol](https://docs.python.org/3/c-api/buffer.html), see
[raw_buffers.nim](https://github.com/yglukhov/nimpy/blob/master/nimpy/raw_buffers.nim).
[tpyfromnim.nim](https://github.com/yglukhov/nimpy/blob/master/tests/tpyfromnim.nim)
contains a very basic test for this (grep `numpy`). Higher level API might
be considered in the future, PRs are welcome.
</details>

<details>
<summary> <b>Question:</b>

Does nim default garbage collector (GC) work?
</summary>

  nimpy internally does everything needed to run the GC properly (keeps the stack bottom
  actual, and appropriate nim references alive), and doesn't introduce any special rules
  on top. So the GC question boils down to proper GC usage in nim shared libraries,
  you'd better lookup elsewhere. The following guidelines are by no means comprehensive,
  but should be enough for the quick start:
  - If it's known there will be only one nimpy module in the process, you should be fine.
  - If there is more than one nimpy module, it is recommended to [move nim runtime out
    to a separate shared library](https://nim-lang.org/docs/nimc.html#dll-generation).
    However it might not be needed if nim references are known to never travel between
    nim shared libraries.
  - If you hit any GC problems with nimpy, whether you followed these guidelines or not,
    please report them to nimpy tracker :)

</details>

## Future directions
* exporting Nim types/functions as Python classes/methods
* High level buffer API

## Stargazers over time

[![Stargazers over time](https://starcharts.herokuapp.com/yglukhov/nimpy.svg)](https://starcharts.herokuapp.com/yglukhov/nimpy)
