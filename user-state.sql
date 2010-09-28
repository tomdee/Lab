select p.name, case when coalesce(o.timestamp, timestamp(0)) < i.timestamp then 'IN' else 'OUT' end as status
from person as p
join
(
	select max(i.timestamp) as timestamp
	from person_log as i
	where i.action = 'IN'
	and i.person_id = 1
) as i on true
left join
(
	select max(o.timestamp) as timestamp
	from person_log as o
	where o.action = 'OUT'
	and o.person_id = 1
) as o on true
where p.id = 1;
