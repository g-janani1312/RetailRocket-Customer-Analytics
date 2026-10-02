CREATE TABLE events (
    timestamp BIGINT,
    visitorid BIGINT,
    event VARCHAR(20),
    itemid BIGINT,
    transactionid BIGINT
);

select count(*) from events;

select * from events limit 10;

select event, count(*) as total_events from events
group by event
order by count(*) desc;

select event, count(distinct visitorid) as unique_visitors
from events
group by event
order by unique_visitors desc;

--FUNNEL ANALYSIS--
with funnel as(
	select
		count(distinct case when event='view' then visitorid end) as viewed,
		count(distinct case when event='addtocart' then visitorid end) as cart,
		count(distinct case when event='transaction' then visitorid end) as purchased
	from events
)
select viewed,cart,purchased,
	round(cart*100.0/viewed,2) as view_to_cart_rate,
	round((viewed-cart)*100.0/viewed,2) as view_to_cart_dropoff,
	round(purchased*100.0/cart,2) as cart_to_purchase_rate,
	round((cart-purchased)*100.0/cart,2) as cart_to_purchase_dropoff
from funnel;

--CUSTOMER SEGMENTATION--
with user_behaviour as(
	select visitorid,
	count(*) as total_events,
	count(*) filter(where event='view') as views,
	count(*) filter(where event='addtocart') as add_to_cart,
	count(*) filter(where event='transaction') as transactions
	from events
	group by visitorid
),

segmented_users as(
	select visitorid,
			case when transactions > 0 then 'Purchaser'
				when add_to_cart > 0 then 'Cart Non-Converter'
				else 'Viewers only'
			end as user_segment
		from user_behaviour
)

select user_segment, count(*) as users,
	round(count(*)*100.0/sum(count(*)) over(),2) as percentage
from segmented_users
group by user_segment
order by users desc;

--CART ABANDONMENT--
with cart_users as(
	select distinct visitorid from events where event='addtocart'),
purchase_users as(
	select distinct visitorid from events where event='transaction')

select 
	count(*) as cart_users,
	count(purchase_users.visitorid) as purchasers,
	count(*) - count(purchase_users.visitorid) as non_converters,
	round((count(*)-count(purchase_users.visitorid))*100.0/count(*),2) as abandonment_rate
from cart_users
left join purchase_users
	on cart_users.visitorid=purchase_users.visitorid;
		
)
)
