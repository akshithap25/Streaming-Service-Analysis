--checking
select * from users limit 5;
select * from content limit 5;
select * from ratings limit 5;
select * from watch_history limit 5;

--(1) top 5 most watched shows
select c.title, count(*) as watch_count
from watch_history w
join content c on w.content_id=c.content_id
group by c.title
order by watch_count desc
limit 5;

--(2) total number of users per location
select location, count(*) as total_users
from users
group by location
order by total_users desc;

--(3) monthly active users
select to_char(watch_time, 'yyyy-mm') as month,
count(distinct user_id) as active_users
from watch_history
group by month
order by month;

--(4) binge-watchers (same show > 3 times)
select u.user_id, u.name, c.title as show_title, count(*) as times_watched
from watch_history w
join users u on u.user_id = w.user_id
join content c on w.content_id = c.content_id
group by u.user_id, u.name, c.title
having count(*) > 3
order by times_watched desc

--(5) genre popularity by device
select c.genre, w.device, count(*) as views
from watch_history w
join content c on w.content_id = c.content_id
group by c.genre, w.device
order by c.genre, views desc;

--(6) total watch time per user
select u.user_id, u.name, sum(c.duration_minutes) as total_watch_time
from watch_history w
join users u on u.user_id = w.user_id
join content c on w.content_id = c.content_id
group by u.user_id, u.name
order by total_watch_time desc
limit 5;

--(7) peak watch times (hourly)
select extract(hour from watch_time) as hour, count(*) as view_count
from watch_history
group by hour
order by view_count desc

--(8) device preference by age group
select 
  case 
    when age < 20 then 'teen'
    when age between 20 and 35 then 'young adult'
    when age between 36 and 50 then 'adult'
    else 'senior'
  end as age_group,
  device,
  count(*) as views
from users u
join watch_history w on u.user_id = w.user_id
group by age_group, device
order by age_group, views desc;

--(9) one top title per genre based on view count	
select genre, title, view_count
from (
  select 
    c.genre, 
    c.title, 
    count(*) as view_count,
    rank() over (partition by c.genre order by count(*) desc) as genre_rank
  from watch_history w
  join content c on w.content_id = c.content_id
  group by c.genre, c.title
) ranked
where genre_rank = 1
order by view_count desc;

--(10) preferred genres by age group
select 
  case 
    when u.age < 20 then 'teen'
    when u.age between 20 and 35 then 'young adult'
    when u.age between 36 and 50 then 'adult'
    else 'senior'
  end as age_group,
  c.genre,
  count(*) as views
from users u
join watch_history w on u.user_id = w.user_id
join content c on w.content_id = c.content_id
group by age_group, c.genre
order by age_group, views desc;

--(11) query: time-of-day buckets
select
  case 
    when extract(hour from watch_time) between 0 and 4 then 'midnight'
    when extract(hour from watch_time) between 5 and 11 then 'morning'
    when extract(hour from watch_time) between 12 and 16 then 'afternoon'
    when extract(hour from watch_time) between 17 and 20 then 'evening'
    else 'night'
  end as time_of_day,
  count(*) as total_views
from watch_history
group by time_of_day
order by total_views desc;

--(12) most preferred genre per location
select location, genre, views
from (
    select 
        u.location,
        c.genre,
        count(*) as views,
        rank() over (partition by u.location order by count(*) desc) as genre_rank
    from users u
    join watch_history w on u.user_id = w.user_id
    join content c on w.content_id = c.content_id
    group by u.location, c.genre
) ranked
where genre_rank = 1
order by location;

--(13) churn + last active days
select 
  u.user_id, 
  u.name, 
  max(w.watch_time) as last_watch,
  current_date - max(w.watch_time)::date as days_since_last_active
from users u
left join watch_history w on u.user_id = w.user_id
group by u.user_id, u.name
order by days_since_last_active desc;

