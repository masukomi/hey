-- interrupts by person 
select 
  p.name, count(p.name ) as interrupts 
from people p 
inner join events_people ep on ep.person_id = p.id 
inner join events e on ep.event_id = e.id 
group by p.name 
order by interrupts desc;


-- interrupts by person by hour
-- grouped by hour
select 
  p.name,
  strftime('%H', e.created_at) hour, count(*) interrupts
from 
  events e 
  inner join events_people ep on ep.event_id = e.id
  inner join people p on ep.person_id = p.id
where e.created_at BETWEEN '2017-05-25' AND 'now'
group by 1, 2
order by hour asc;
-- grouped by person
select 
  p.name,
  strftime('%H', e.created_at) hour, count(*) interrupts
from 
  events e 
  inner join events_people ep on ep.event_id = e.id
  inner join people p on ep.person_id = p.id
where e.created_at BETWEEN '2017-05-25' AND 'now'
group by 2,1
order by p.name asc;


-- interrupts by hour
select  strftime('%H', created_at) hours, count(*) interrupts from events group by hours;

-- events since date
select * from events WHERE strftime('%Y-%m-%d', created_at) BETWEEN '2017-05-27' AND 'now';

-- count of people by events
 select e.id, ( select count(*) from events_people  where events_people.event_id = e.id)

 from
  events e 
  inner join events_people ep on ep.event_id = e.id
  inner join people p on ep.person_id = p.id
	group by 1
  ;

-- list of events that only had person x
-- actually the event plus the count
select e.id, ( select count(*) from events_people  where events_people.event_id = e.id) epc
from
events e 
inner join events_people ep on ep.event_id = e.id
inner join people p on ep.person_id = p.id
where epc = 1
and p.id = 2
group by 1
;


