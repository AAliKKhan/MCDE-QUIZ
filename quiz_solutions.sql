-- Section 1 (JOINS)

-- task 1
select
    so.order_id,
    sc.first_name + ' ' + sc.last_name as customer_name,
    ss.store_name,
    st.first_name + ' ' + st.last_name as staff_name
from sales.orders as so
join sales.customers as sc
    on so.customer_id = sc.customer_id
join sales.stores as ss
    on so.store_id = ss.store_id
join sales.staffs as st
    on so.staff_id = st.staff_id
order by so.order_id asc


-- task 2
select
    pp.product_name,
    pb.brand_name,
    pc.category_name
from production.products as pp
left join production.brands as pb
    on pp.brand_id = pb.brand_id
left join production.categories as pc
    on pp.category_id = pc.category_id
order by pp.product_id asc


-- task 3
select
    sc.customer_id,
    sc.first_name + ' ' + sc.last_name as customer_name,
    sc.city,
    sc.email
from sales.customers as sc
left join sales.orders as so
    on sc.customer_id = so.customer_id
where so.order_id is null
order by sc.customer_id asc


-- Section 2 (GROUP BY)

-- task 4
select
    ss.store_name,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_revenue
from sales.stores as ss
join sales.orders as so
    on ss.store_id = so.store_id
join sales.order_items as oi
    on so.order_id = oi.order_id
group by ss.store_name
order by total_revenue desc


-- task 5
select
    pb.brand_id,
    count(pp.product_id) as total_products,
    avg(pp.list_price) as avg_price,
    max(pp.list_price) as max_price
from production.brands as pb
join production.products as pp
    on pb.brand_id = pp.brand_id
group by pb.brand_id
having count(pp.product_id) > 5


-- task 6
select
    year(o.order_date) as order_year,
    month(o.order_date) as order_month,
    count(distinct o.order_id) as total_orders,
    sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_revenue
from sales.orders as o
join sales.order_items as oi
    on o.order_id = oi.order_id
where year(o.order_date) = 2017
group by year(o.order_date), month(o.order_date)
order by order_month asc


-- Section 3 (Subqueries)

-- task 7
select
    p1.product_name,
    p1.category_id,
    p1.list_price
from production.products as p1
where p1.list_price > (
    select
        avg(p2.list_price) as avg_price
    from production.products as p2
    where p2.category_id = p1.category_id
)
order by p1.category_id asc


-- task 8
select
    c.customer_id,
    c.first_name + ' ' + c.last_name as customer_name,
    count(o.order_id) as order_count
from sales.customers as c
join sales.orders as o
    on c.customer_id = o.customer_id
group by c.customer_id, c.first_name, c.last_name
having count(o.order_id) > (
    select avg(t.order_count * 1.0)
    from (
        select count(*) as order_count
        from sales.orders
        group by customer_id
    ) as t
)
order by order_count desc


-- Section 4 (CTEs)

-- task 9
with customer_spend as (
    select
        c.customer_id,
        c.first_name + ' ' + c.last_name as customer_name,
        sum(oi.quantity * oi.list_price * (1 - oi.discount)) as total_spend
    from sales.customers as c
    join sales.orders as o
        on c.customer_id = o.customer_id
    join sales.order_items as oi
        on o.order_id = oi.order_id
    group by c.customer_id, c.first_name, c.last_name
),
customer_label as (
    select
        customer_id,
        customer_name,
        total_spend,
        rank() over (order by total_spend desc) as spend_rank,
        case
            when total_spend > avg(total_spend) over () then 'High'
            else 'Regular'
        end as spend_label
    from customer_spend
)
select top 10
    customer_id,
    customer_name,
    total_spend,
    spend_rank,
    spend_label
from customer_label
order by spend_rank


-- task 10
with product_sales as (
    select
        p.product_id,
        p.product_name,
        p.category_id,
        sum(oi.quantity) as total_sold
    from production.products as p
    join sales.order_items as oi
        on p.product_id = oi.product_id
    group by p.product_id, p.product_name, p.category_id
),
ranked_products as (
    select
        product_id,
        product_name,
        category_id,
        total_sold,
        rank() over (
            partition by category_id
            order by total_sold desc
        ) as sales_rank
    from product_sales
),
stock_totals as (
    select
        product_id,
        sum(quantity) as total_stock
    from production.stocks
    group by product_id
)
select
    c.category_name,
    r.product_name,
    r.total_sold,
    coalesce(st.total_stock, 0) as stock_available
from ranked_products as r
join production.categories as c
    on r.category_id = c.category_id
left join stock_totals as st
    on r.product_id = st.product_id
where r.sales_rank = 1
order by c.category_name
