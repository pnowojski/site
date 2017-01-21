---
title: SQL-on-anything - talk at Warsaw Hadoop User Group
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

