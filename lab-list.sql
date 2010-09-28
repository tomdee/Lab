select p.name
from person as p
join
(
	select i.person_id, max(i.timestamp) as timestamp
	from person_log as i
	where i.action = 'IN'
	group by i.person_id
) as i on i.person_id = p.id
left join
(
	select o.person_id, max(o.timestamp) as timestamp
	from person_log as o
	where o.action = 'OUT'
	group by o.person_id
) as o on o.person_id = p.id
where coalesce(o.timestamp, timestamp(0)) < i.timestamp;
