class APlacePlatforms : AActor
{
    UPROPERTY()
    TSubclassOf<AActor> Platform;

    UPROPERTY()
    int rows = 3;

    UPROPERTY()
    int cols = 5;

    UPROPERTY()
    float SpaceInBetween = 300;

    UPROPERTY()
    float enemyOffset = 900;

    UPROPERTY()
    TArray<APlatform> Platforms;

    UPROPERTY()
    TArray<APlatform> PlatformsPlayer;

    UPROPERTY()
    TArray<APlatform> PlatformsEnemies;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        FVector baseLocation = GetActorLocation();
        FRotator enemyRotation = FRotator(0.0, 180.0, 0.0);

        float totalWidth = (cols - 1) * SpaceInBetween;
        float totalHeight = (rows - 1) * SpaceInBetween;
        float totalOffSet = enemyOffset;
        FVector playerGridCenter = baseLocation - FVector(0, totalOffSet / 2.0, 0);
        FVector enemyGridCenter = baseLocation + FVector(0, totalOffSet / 2.0, 0);

        for (int col = 0; col < cols; col++)
        {
            for (int row = 0; row < rows; row++)
            {
                FVector spawnLocation;
                spawnLocation.X = playerGridCenter.X + col * SpaceInBetween - totalWidth / 2.0;
                spawnLocation.Y = playerGridCenter.Y + row * SpaceInBetween - totalHeight / 2.0;
                spawnLocation.Z = baseLocation.Z + -190.0;

                AActor spawned = SpawnActor(Platform, spawnLocation, FRotator::ZeroRotator);
                APlatform p = Cast<APlatform>(spawned);
                if (p != nullptr)
                {
                    PlatformsPlayer.Add(p);
                    Platforms.Add(p);
                    p.GridX = col;
                    p.GridY = row;
                    p.ChangeColor(EPlatformType::Base);
                }
            }
        }

        for (int col = 0; col < cols; col++)
        {
            for (int row = 0; row < rows; row++)
            {
                FVector spawnLocation;
                spawnLocation.X = enemyGridCenter.X + col * SpaceInBetween - totalWidth / 2.0;
                spawnLocation.Y = enemyGridCenter.Y + row * SpaceInBetween - totalHeight / 2.0;
                spawnLocation.Z = baseLocation.Z + -190.0;

                AActor spawned = SpawnActor(Platform, spawnLocation, enemyRotation);
                APlatform p = Cast<APlatform>(spawned);
                if (p != nullptr)
                {
                    PlatformsEnemies.Add(p);
                    Platforms.Add(p);
                    p.GridX = col;
                    p.GridY = row;
                    p.ChangeColor(EPlatformType::Enemy);
                }
            }
        }

    }
}