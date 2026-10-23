use AnaliseComercial;

select * from pedidos;
select * from produtos;
select * from clientes;
select * from Metasmensais;
select * from itenspedidos;



--1.	Qual é o faturamento total e sua evolução mensal?

Go
select Month(p.datapedido) as mes,
Year (p.datapedido) as ano,
SUM(i.quantidade) as qtd_vendas,
SUM(i.quantidade * pr.precounitario) as faturamentoMensal,
SUM(SUM(i.quantidade * pr.precounitario)) OVER () as faturamento_t
from produtos as pr
inner join itenspedidos as i
on pr.produtoid = i.produtoid
inner join pedidos as p
on p.pedidoid = i.pedidoid
where p.statuspedido = 'entregue'
group by Year(p.datapedido) ,
Month(p.datapedido)
order by ano, mes;

--2.	Quais lojas apresentam melhor e pior desempenho em faturamento?

Go
select l.lojaid,
SUM(i.quantidade) as qtd_vendas,
SUM(i.quantidade * pr.precounitario) as faturamentoMensal,
SUM(SUM(i.quantidade * pr.precounitario)) OVER () as faturamento_t
from produtos as pr
inner join itenspedidos as i
on pr.produtoid = i.produtoid
inner join pedidos as p
on p.pedidoid = i.pedidoid
inner join lojas as l
on l.lojaid = p.lojaid
where p.statuspedido = 'entregue'
group by l.lojaid
order by faturamentoMensal desc;

--3.	Quais categorias e produtos geram mais receita?

Go
select pr.categoria, pr.nomeproduto,
SUM(i.quantidade) as qtd_vendas,
SUM(i.quantidade * pr.precounitario) as faturamentoMensal,
SUM(SUM(i.quantidade * pr.precounitario)) OVER () as faturamento_t 
from produtos as pr 
inner join itenspedidos as i 
on pr.produtoid = i.produtoid 
inner join pedidos as p 
on p.pedidoid = i.pedidoid 
inner join lojas as l 
on l.lojaid = p.lojaid 
where p.statuspedido = 'entregue' 
group by pr.nomeproduto, pr.categoria
order by faturamentoMensal desc;


--4.	Quais produtos apresentam maior lucro e margem de lucro?

Go
select pr.nomeproduto,
SUM(i.quantidade) as qtd_vendas,
SUM(i.quantidade * (pr.precounitario)) as faturamentoMensal,
SUM(i.quantidade * (pr.precounitario - pr.custounitario)) as lucros_t,
round(SUM(i.quantidade * (pr.precounitario - pr.custounitario)) * 100.0 / NULLIF(SUM(i.quantidade * pr.precounitario),0),2) as margem_lucro
from produtos as pr 
inner join itenspedidos as i 
on pr.produtoid = i.produtoid 
inner join pedidos as p 
on p.pedidoid = i.pedidoid 
inner join lojas as l 
on l.lojaid = p.lojaid 
where p.statuspedido = 'entregue' 
group by pr.nomeproduto
order by faturamentoMensal desc;


--5.	Quais lojas atingiram suas metas mensais de faturamento?
Go
select l.lojaid, month(m.mesreferencia) as mes_ref, m.metafaturamento,
SUM(i.quantidade) as qtd_vendas,
SUM(i.quantidade * pr.precounitario) as faturamentoMensal,
SUM(SUM(i.quantidade * pr.precounitario)) OVER () as faturamento_t
from produtos as pr
inner join itenspedidos as i
on pr.produtoid = i.produtoid
inner join pedidos as p
on p.pedidoid = i.pedidoid
inner join metasmensais as m
on p.lojaid = m.lojaid
AND YEAR(p.datapedido) = YEAR(m.mesreferencia)
AND MONTH(p.datapedido) = MONTH(m.mesreferencia)
inner join lojas as l
on l.lojaid = p.lojaid
where p.statuspedido = 'entregue'
group by l.lojaid, month(m.mesreferencia), m.metafaturamento
order by faturamentoMensal desc;


--6.	Qual é o ticket médio dos pedidos?

Go
select COUNT(DISTINCT(p.pedidoid)) as pedidos_distintos, Month(p.datapedido) as mes,
Year (p.datapedido) as ano,
SUM(i.quantidade * pr.precounitario)  / NULLIF(COUNT(DISTINCT p.pedidoid),0) as media
from produtos as pr
inner join itenspedidos as i
on pr.produtoid = i.produtoid
inner join pedidos as p
on p.pedidoid = i.pedidoid
where p.statuspedido = 'entregue'
group by Year(p.datapedido) ,
Month(p.datapedido)
order by ano, mes


--7.	Quais clientes e segmentos geram mais receita?
Go
select c.clienteid, c.nomecliente,
SUM(i.quantidade) as qtd_vendas,
SUM(i.quantidade * pr.precounitario) as faturamentoMensal,
SUM(SUM(i.quantidade * pr.precounitario)) OVER () as faturamento_t
from produtos as pr
inner join itenspedidos as i
on pr.produtoid = i.produtoid
inner join pedidos as p
on p.pedidoid = i.pedidoid
inner join clientes as c
on c.clienteid = p.clienteid
where p.statuspedido = 'entregue'
group by c.clienteid, c.nomecliente
order by faturamentoMensal desc;


--8.	Quais formas de pagamento são mais utilizadas?


select count(pedidoid) as qtd_pedido, formapagamento from pedidos 
group by formapagamento;


--9.	Qual é o impacto dos descontos sobre a receita e o lucro?
SELECT
    MONTH(p.datapedido) AS mes,
    SUM(pc.desconto_pedido) AS desconto_pedido,
    SUM(pc.desconto_itens) AS desconto_itens,
    SUM(pc.faturamento_bruto - pc.desconto_itens - pc.desconto_pedido) AS faturamento_pos_desconto,
    YEAR(p.datapedido) AS ano,
    SUM(pc.qtd_vendas) AS qtd_vendas,
    SUM(pc.faturamento_bruto) AS faturamento_t
FROM pedidos AS p
INNER JOIN (
    SELECT
        p.pedidoid,
        SUM(i.quantidade * pr.precounitario) AS faturamento_bruto,
        SUM(i.quantidade * pr.precounitario * i.descontoitempct / 100.0) AS desconto_itens,
        (SUM(i.quantidade * pr.precounitario)
        - SUM(i.quantidade * pr.precounitario * i.descontoitempct / 100.0))
        * MAX(p.descontopedidopct) / 100.0 AS desconto_pedido,
        SUM(i.quantidade) AS qtd_vendas
    FROM produtos AS pr
    INNER JOIN itenspedidos AS i
        ON pr.produtoid = i.produtoid
    INNER JOIN pedidos AS p
        ON p.pedidoid = i.pedidoid
    WHERE p.statuspedido = 'entregue'
    GROUP BY p.pedidoid
) AS pc
    ON p.pedidoid = pc.pedidoid
WHERE p.statuspedido = 'entregue'
GROUP BY YEAR(p.datapedido), MONTH(p.datapedido)
ORDER BY ano, mes;
