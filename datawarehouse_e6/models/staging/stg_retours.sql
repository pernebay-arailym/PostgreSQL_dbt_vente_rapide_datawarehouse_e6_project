with source as (
    select * from {{ ref('raw_retours') }}
),

renamed as (
    select
        cast(retour_id as integer) as id_retour,
        cast(commande_id as integer) as id_commande,
        cast(produit_id as integer) as id_produit,
        cast(client_id as integer) as id_client,
        cast(date_retour as date) as date_retour,
        cast(motif as varchar(50)) as motif_retour,
        cast(montant_rembourse as numeric(10, 2)) as montant_rembourse
    from source
)

select * from renamed