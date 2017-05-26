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

Later on you can, optionally, go back and tag the event, leave a note, 
or generate reports graphing all your past interruptions.


## Instructions

### Installation
TODO: add installation instructions

### Usage

#### Record an event

`hey <person(s)>` 

`<person(s)>` is a space separated list of one or more
people's names. 

Note: all names are downcased in the database to save worrying about multiple
entries when you accidentally type "bob" one time and "Bob" the next.

#### Viewing recent events
**NOT IMPLEMENTED**  

`hey list`

```
Recent interrupts: Chronological order
Starting at midnight yesterday. 

ID | Person(s) | When                 | Tags
2. | Bob, Mary | 4/12/17 14:23        | meeting, scheduled
3. | Bob       | 4/12/17 14:26        |
4. | Sam       | 4/12/17 16:11        | question 
5. | Mary      | 4/12/18 09:22        | task list
```



#### Tag an event
`hey tag <event id> <tag(s)>`  
`hey retag <event id> <tag(s)>`

`<event id>` is one of the ids shown by `hey list` or `hey data`

`<tag(s)>` is a space separated list of tags to associated with this event.

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
**NOT IMPLEMENTED**  

`hey delete <event id>`

`<event id>` is one of the ids shown by `hey list` or `hey data`

Permanently deletes the specified record. There is no undo.

#### Exporting Data
**NOT IMPLEMENTED**  

`hey data`

To be determined. YAML? TOML? JSON? 

Whatever format it is should be something that other command line tools can
ingest easily. Additionally we may want a simple query language or something
similar to allow you to export just the data for a specific person, or date
range.


## Testing
Set the `HEY_DB` environement variable to a path to your test DB and `hey` will
use that instead. That way you can test / develop on it in a test db but still
use it to track real interruptions in the default db.

