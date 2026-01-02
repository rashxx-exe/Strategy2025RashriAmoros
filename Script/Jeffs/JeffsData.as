USTRUCT()
struct FJeffsData 
{
    UPROPERTY(EditAnywhere)
    TSubclassOf<AJeff> AActorToSpawn;

    UPROPERTY()
    FName JeffsName;

    UPROPERTY()
    EJeffsType JeffType;

    UPROPERTY()
    UTexture2D JeffsImg;

    UPROPERTY()
    int32 JeffsVida;

    UPROPERTY()
    int32 JeffsAtaque;
}
