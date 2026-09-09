with stg_retours as (
    select * from {{ ref('stg_retours') }}
),

dim_client as (
    select * from {{ ref('dim_client') }}
),

dim_produit as (
    select * from {{ ref('dim_produit') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

fact_retours as (
    select
        r.id_retour,
        r.id_commande,
        r.id_client,
        r.id_produit,
        r.date_retour,
        d.date_id as id_date_retour,
        r.motif_retour,
        r.montant_rembourse
    from stg_retours r
    left join dim_client c on r.id_client = c.client_id
    left join dim_produit p on r.id_produit = p.produit_id
    left join dim_date d on r.date_retour = d.date_jour
)

select * from fact_retours