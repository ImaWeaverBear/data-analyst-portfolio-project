CREATE TABLE "FinPro".sales_analysis AS
SELECT

    -- Transaction
    v."Venda_ID",
    v."Data da Venda",
    v."Quantidade",
    v."Preço Unitário",

    -- Customer
    c."Cliente_ID",
    c."Nome" AS customer_name,
    c."Género",
    c."Idade",
    c."Cidade",

    -- Product
    p."Produto_ID",
    p."Nome" AS product_name,
    p."Categoria",
    p."Cor",
    p."Tamanho",
    p."Preço",
    p."Custo_Aquisição",

    -- Store
    l."Loja_ID",
    l."Nome" AS store_name,
    l."Região",
    l."Cidade" AS store_city,
    l."Tipo"

FROM "FinPro".vendas v

LEFT JOIN "FinPro".clientes c
ON v."Cliente_ID" = c."Cliente_ID"

LEFT JOIN "FinPro".produtos p
ON v."Produto_ID" = p."Produto_ID"

LEFT JOIN "FinPro".lojas l
ON v."Loja_ID" = l."Loja_ID";