(Official homepage at [interrupttracker.com](https://interrupttracker.com))

----

Please note: This codebase was a quick hack that got out of hand. I
was also pretty new to Scheme at the time. It's been rewritten twice over the years. The current version is now in Raku and
[can be found here](https://github.com/masukomi/hey_3). The latest
version supports Time Tracking too. Not just Interruption Tracking.

This has been updated to work with Chicken 5, but I'm not using this
version anymore so I'm not guaranteeing anything ;) 

----

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
You'll have to build from source. This requires
[Chicken Scheme](https://www.call-cc.org/) to be installed.  


#### Building from source

1. Run `./install_chicken_eggs.sh` to install the libraries it uses.
2. Run `./build.sh` to build the `hey` executable. 
3. copy `default.db` to `~/.local/share/hey/hey.db`

You can use a different location by specifying the HEY_DB
environment variable, or tweaking the config. See Testing below.

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

`hey <names> + <tags>`

`<names>` is a space separated list of one or more
people's names.

`<tags>` is a space separated list of tags to associated with this event.

#### Viewing recent events
`hey` `hey list` or `hey list 3`

Shows you the most recent interruptions. Defaults to 25.

```
Last 25 interruptions in chronological order...

 | ID  | When                | Who       | Tags               |
 | 105 | 2017-06-17 08:53:48 | Bob, Mary | meeting, scheduled |
 | 106 | 2017-06-17 08:53:55 | Bob       | question           |
 | 109 | 2017-06-28 11:35:05 | Sam       | task               |
```

#### Seeing who's been interrupting you and why

`hey who`

```
 | Who        | Interrupts | Tags                                                      |
 | simon      | 3          | manager, question                                         |
 | roman      | 5          | manager, question                                         |
 | andres     | 9          | investigation, question, tl                               |
 | nima       | 10         | merge_request, question, random, request, tl,             |
 | sonal      | 10         | coordination, instructions, planning, question, tl        |
 | greg       | 11         | pairing, question, release_request, tl                    |
 | mike_o     | 13         | beginner, pair_request, question, tl, undocumented        |
```

#### Reporting on recent events
`hey graph` will list all graphing options

`hey graph people-by-hour`

Collates your data, and loads it in a pretty graph on
InterruptTracker.com for you. You can see an example 
[here](https://interrupttracker.com/stacked_bar_chart.html)

NOTE: currently limited to graphing the past 7 days. This will change.

`hey graph interrupts-by-day`

Same thing, but graphs the number of interrupts by day as a 
line chart.


`hey graph tags-by-hour`

Shows you a stacked bar chart of what tags happen during what hours.

NOTE: currently limited to graphing the past 7 days. This will change.

#### Tag an event
`hey tag <event id> <tags>`  
`hey retag <event id> <tags>`

`<event id>` is one of the ids shown by `hey list` or `hey data`

`<tags>` is a space separated list of tags to associated with this event.

If you `tag` the same event twice then the new tags will be appended to the list.

If you `retag` an event the new list will replace the old one

#### Show existing tags
`hey tags`

Lists all the tags currently in the system.

#### Comment on an event
`hey comment <event id> <my comment string>`

`<event id>` is one of the ids shown by `hey list` or `hey data`

`<my comment string>` is... your comment. Doesn't have to be in quotes. Ends
when you hit enter.

Note if you comment on the same event twice it will replace the existing
comment with your new one. 

**Unfortunately** none of the current reports expose these comments.
There is [an open ticket](https://github.com/masukomi/hey/issues/11) to make
these visible. If you want to record them now they will eventually be displayed.

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
