---
title: SQL-on-anything - talk at Warsaw Hadoop User Group
author: kokosing
header:
  image: 'https://pbs.twimg.com/media/C28_V44XgAIkcD7.jpg:large'
---

Just in case any of you were close to Warsaw (Poland) and you do not have any
plans for Tuesday (January 24) evening. There will be Presto related talk at
Warsaw Hadoop User Group (WHUG) meetup. Go to [WHUG
website](https://www.meetup.com/warsaw-hug/events/236467094/) to find more
information.

> One of the key differences between Presto and Hive, also a crucial functional
> requirement Facebook made when launching this new SQL engine project, was to
> have the opportunity to query different kinds of data sources via a uniform
> ANSI SQL interface. Presto, an open source distributed analytical SQL engine,
> implements this with its connector architecture, creating an abstraction
> layer for anything that can be expressed in a row-like format, ranging
> from MySQL tables, HDFS, Amazon S3 to NoSQL stores, Kafka streams and
> proprietary data sources. Presto connector SPI allows anyone to implement a
> Presto connector and benefit from the capabilities of the Presto SQL
> engine, enabling them to join data from various sources within a single SQL
> query.

Together with [Karol](https://github.com/sopel39) we will be speaking about data
source federation with Presto. We will describe how Presto can be fed with
data and how such data can be streamed through or integrated with other data
sources. This will also cover architecture of Presto Connectors as well as
their functionalities (like transactions, access control, predicate pushdown
etc.).

I am not going into much details as I do not want to spoil the meeting and because
that Presto connectors deserver separate post.

Hope to see you there!

---
---
---

## An update

The meetup happened many days ago and to make this post complete I would like 
to share the related media files.
Obviously I have a presentation slides. Also I have a single picture which 
was taken during the meetup and shared on 
[twitter](https://twitter.com/MarcinChoinski/status/823946905487020032).
Moreover the organizer prepared a video, so you will not 
only have a chance to read but also you have the possibility to watch. Unfortunately (or fortunately if you are 
not fluent in English) the presentation was conducted in Polish.

<iframe src="//www.slideshare.net/slideshow/embed_code/key/eev9mqp4AzmgiR" width="595" height="485" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe> <div style="margin-bottom:5px"> <strong> <a href="//www.slideshare.net/GrzegorzKokosiski/presto-sql-on-anything-72220474" title="Presto - SQL on anything" target="_blank">Presto - SQL on anything</a> </strong> from <strong><a target="_blank" href="//www.slideshare.net/GrzegorzKokosiski">Grzegorz Kokosiński</a></strong> </div>

![Picture taken by Marcin Choiński and shared via twitter](https://pbs.twimg.com/media/C28_V44XgAIkcD7.jpg:large)

<iframe width="560" height="315" src="https://www.youtube.com/embed/iN14bUUL1pE" frameborder="0" allowfullscreen></iframe>
