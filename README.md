# ccbootstrap
A simple program for setting up a CraftOS environment with variably simple configuration.

I made this program since - while yes, most of the time it's unnecessary - it could get some use. It's also a fun messing around project.

## Usage
Before running `bootstrap.lua`, make sure you have a properly-made `ccbootstrap.json` in the same directory. Here's a pretty loaded example:

```jsonc
{
    "meta":{ // Required
        "name":"Example",
        "description":"Example ccbootstrap.json",
        "make_startup":true, // Required - make a startup file for things like the path operation
        "verbose":true // Required - verbosity
    },
    "operations":{ // Required
        "settings":{ // Optional - Set settings
            "bios.use_cash":true
            // So on and so forth
        },
        "path":{ // Optional - Add onto or set the shell path
            "action":"addto", // Required - Can be 'addto' or 'rewrite'
            "string":"/bin" // Required - Do not start with ':', only add in-between.
        },
        "fetch"[ // Optional - fetch files from github repositories
            {
                "repo":"torvalds/linux", // Required - The repo
                "file":"Makefile", // Required - The filename
                "branch":"master" // Required - The branch to pull from
            }
            // So on and so forth
        ]
    }
}
```

While all `operations` *are* optional, putting no operations just has `ccbootstrap` do nothing. Additionally, any *required* components inside of any of the `operations` are, of course, required for that operation.

You also don't need *all* operations present - just one or some.

And for `operations.settings`, instead of:
```
bios.use_cash will be true
list.show_hidden will be true
(etc etc...)
End of settings list - saving.
```

You'll get:
```
Setting and saving settings.. set and saved
```

`meta.verbose` will never affect `operations.path`.
`meta.verbose` will eventually affect `operations.fetch`.

-----

Below are all operations, in-depth, one-by-one:

### `settings`
The `settings` operation is essentially just a table of settings and their values in `key:value` pairs. If a setting isn't a valid setting, it gets ignored.

### `path`
The `path` operation might be a little confusing for some. It modifies the shell path, which is the thing ComputerCraft uses to find and execute programs from anywhere in the system. It has two required components: the `action` and the `string`.

The `action` can either be `addto` or `rewrite`. `addto` will add the `string` to the end of the shell path. `rewrite` will overwrite the shell path to be the `string`.

For example, let's work with a shell path of `.:/rom/programs`, and a string of `/bin`. `addto` would result in the shell path being `.:/rom/programs:/bin`. `rewrite` would result in the shell path being `/bin`.

If the `action` or `string` is not present, the entire operation is skipped.

### `fetch`
The `fetch` operation is a list full of tables, each with three components: `repo`, `file`, and an optional `branch`. The `repo` component is what Github repository to check, and the `file` component is what file to get from the repository. The `branch` component is what branch to pull from. **If the branch is invalid, ccbootstrap will default to `master`.** If that doesn't exist, **that `fetch` will be skipped.** If a file or repository isn't found, ccbootstrap will keep on and carry on after informing the user.
