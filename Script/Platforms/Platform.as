UENUM()
enum EPlatformType
{
    Base,
    Attack,
    Movement,
    Enemy,
    Healing,
    Support,
    Shield
}

class APlatform : AActor
{
    UPROPERTY(DefaultComponent)
    USkeletalMeshComponent Mesh;

    UPROPERTY(EditAnywhere)
    UMaterial BaseMaterial;

    UPROPERTY(EditAnywhere)
    UMaterial AttackMaterial;

    UPROPERTY(EditAnywhere)
    UMaterial MovementMaterial;

    UPROPERTY(EditAnywhere)
    UMaterial EnemyMaterial;

    UPROPERTY(EditAnywhere)
    UMaterial HealingMaterial;

    UPROPERTY(EditAnywhere)
    UMaterial SupportMaterial;

    UPROPERTY(EditAnywhere)
    UMaterial ShieldMaterial;

    UPROPERTY()
    UAnimationAsset IdleAnimation;

    EPlatformType PlatformType;
    EPlatformType PlatformType2;
    int GridX;
    int GridY;

    default
    {
        PlatformType = EPlatformType::Base;
        PlatformType2 = EPlatformType::Base;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Mesh.PlayAnimation(IdleAnimation, true);
    }

    UFUNCTION()
    void ChangeColor(EPlatformType NewType)
    {

        PlatformType = NewType;

        
        if (NewType == EPlatformType::Base)
        {
            Mesh.SetMaterial(0, BaseMaterial);
        }
        else if (NewType == EPlatformType::Attack)
        {
            Mesh.SetMaterial(0, AttackMaterial);
        }
        else if (NewType == EPlatformType::Movement)
        {
            Mesh.SetMaterial(0, MovementMaterial);
        }
        else if (NewType == EPlatformType::Enemy)
        {
            Mesh.SetMaterial(0, EnemyMaterial);
        }
        else if (NewType == EPlatformType::Healing)
        {
            Mesh.SetMaterial(0, HealingMaterial);
        }
        else if (NewType == EPlatformType::Support)
        {
            Mesh.SetMaterial(0, SupportMaterial);
        }

        // PARA PRUEBAS
        else if (NewType == EPlatformType::Shield)
        {
            Mesh.SetMaterial(0, ShieldMaterial);
        }
    }

    void ShieldPlat(EPlatformType PlatShield)
    {
        PlatformType2 = PlatShield;
    }
}