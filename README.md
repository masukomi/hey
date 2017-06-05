(Official homepage at [interrupttracker.com](https://interrupttracker.com))
# Hey

"Hey! I've got a question."  
"Hey take a look at this."  
"Hey!"

## Sound familiar?  
Interested in tracking just how many times you're interrupted and by who? 

Well hey, maybe hey is the tool for you.

When someone walks up to you and starts talking, breaks your concentration with
yet another slack message, or diety forbid, actually calls your phone...just
type `hey <person's name>` on the command line.

That's it. Entries will be created in a SQLite database for the event, the
person, their association, and when it happened.

Want to start tracking _why_ people are interrupting you? After the interruption 
you can, optionally, list and tag the events, leave a note, 
or generate reports graphing all your past interruptions.

Track it for long enough and patterns are sure to emerge. Maybe you'll find 
that a little documentation could save you hours a week. Maybe you'll find that
one person that's devouring more time than anyone else and discuss a better way to
handle things.

## Instructions

### Installation
#### Mac Users
You can [download the latest version here.](https://interrupttracker.com/downloads/hey.dmg)
Open that up and follow the instructions in the README.md

Unfortunately, right now it requires that you have 
[Chicken Scheme](https://www.call-cc.org/) installed.  There's a library file
it's linking to that I haven't extracted into the build yet. Sorry.

#### Building from source
In this case there's no getting around the need for having 
[Chicken Scheme](https://www.call-cc.org/) installed.

Once you've done that building it is pretty easy

For linux:
```
./build.sh libraries
./build.sh linux
```

The first command will create a `hey_libs` directory and install all the require
"eggs" (third party libraries). You should only ever need to do that once. 
The second command will build the modules and an executable, and place them in
the `hey_libs` directory, then put together a cli tool called `hey` that will
run the real `hey` executable from within that directory, because it needs to be
run from within the same directory as its libraries.

On macOS we get around this by bundling it all up in a `.app` folder and hiding
the libs in there. But, we still need the helper cli script.

To build the macOS .app version from scratch you'll need to have the 
[appdmg npm tool](https://www.npmjs.com/package/appdmg) installed.

Once you've got that just run

```
./build.sh libraries
./build.sh mac

#### Geeks on other platforms
Hey is written in [Chicken Scheme](https://www.call-cc.org/), 
which generates standard C files. As a
result, you should be able to compile it on most systems. Once you've 
cloned the repo and installed Chicken Scheme, try running the `build.sh` and 
tell it you want to install `libraries`

After that... Well, I'm happy to help but I only use macOS. 

#### Everyone Else
Sorry. :(

### Usage

#### Record an event

`hey <names>` 

`<names>` is a space separated list of one or more
people's names. 

Note: all names are downcased in the database to save worrying about multiple
entries when you accidentally type "bob" one time and "Bob" the next.

#### Record an event and tag it at the same time
Most of the time you create an event as it happens, and you don't know what it's
going to be about yet, so you create it, then tag it later. But sometimes you
create it just _after_ it happened and you _do_ know what it was about.

`hey <names> +tag <tags>`

`<names>` is a space separated list of one or more
people's names.

`<tags>` is a space separated list of tags to associated with this event.

#### Viewing recent events
`hey list`

```
Recent interrupts: Chronological order
Starting at midnight yesterday. 

ID | Who       | When                 | Tags
2. | Bob, Mary | 4/12/17 14:23        | meeting, scheduled
3. | Bob       | 4/12/17 14:26        |
4. | Sam       | 4/12/17 16:11        | question 
5. | Mary      | 4/12/18 09:22        | task list
```

#### Reporting on recent events
`hey graph` will list all graphing options

`hey graph people-by-hour`

Collates your data, and loads it in a pretty graph on
InterruptTracker.com for you. You can see an example 
[here](https://interrupttracker.com/stacked_bar_chart.html)


#### Tag an event
`hey tag <event id> <tags>`  
`hey retag <event id> <tags>`

`<event id>` is one of the ids shown by `hey list` or `hey data`

`<tags>` is a space separated list of tags to associated with this event.

If you `tag` the same event twice then the new tags will be appended to the list.

If you `retag` an event the new list will replace the old one

#### Comment on an event
`hey comment <event id> <my comment string>`

`<event id>` is one of the ids shown by `hey list` or `hey data`

`<my comment string>` is... your comment. Doesn't have to be in quotes. Ends
when you hit enter.

Note if you comment on the same event twice it will replace the existing
comment with your new one.

#### Delete accidental interrupts
`hey delete <event id>`

`<event id>` is one of the ids shown by `hey list` or `hey data`

Permanently deletes the specified record. There is no undo.

#### Delete accidental people
`hey kill <name>`

_(Note: No humans will be harmed in the execution of this
command.)_

Deletes that person from your database, and removes them from
any events. If there are events that _only_ involved that
person, they will also be deleted.

#### Exporting Data
**NOT IMPLEMENTED**  

`hey data`

To be determined. YAML? TOML? JSON? 

Whatever format it is should be something that other command line tools can
ingest easily. Additionally we may want a simple query language or something
similar to allow you to export just the data for a specific person, or date
range.


## Testing
`hey` looks for a json file at `~/.config/hey/config.json`

To have `hey` use a different database location set the value of `HEY_DB` to be
the path to your SQLite file.

For example:

    {
      "HEY_DB": "~/path/to/my/hey.test.db"
    }

When writing new code for hey it's often useful to have it tell you which db its
pulling from. Add `"show_db_path": true` to the config hash and it'll display
the db path when you run `hey list`. This defaults to false if it's not in your
config.

If you are building `hey` from source and not using the shell script created by
the installer then you can set the `HEY_DB` environment variable to a path to
your test DB and `hey` will use that instead. That way you can test / develop on
it in a test db but still use it to track real interruptions in the default db.

The environment variable trumps the config file, and the config file trumps 
the default.
