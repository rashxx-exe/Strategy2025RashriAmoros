class ACamera : APawn
{
    UPROPERTY(DefaultComponent, RootComponent)
    UCameraComponent Camera;

    FVector Target = FVector(0, 0, 0);

    float Distance = 1850.0f;

    float Yaw = 0.0f;
    float Pitch = 50.0f;
    float Roll = 100;

    bool bFixedApplied = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CameraOnFixed();
        bFixedApplied = true;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        auto gs = Cast<AJeffsGameState>(GetWorld().GetGameState());
        if (gs == nullptr) return;

        if (gs.isCameraFix)
        {
            if (!bFixedApplied)
            {
                CameraOnFixed();
                bFixedApplied = true;
            }
        }
        else if (!gs.isCameraFix)
        {
            bFixedApplied = false;
            Distance = 1850.0f;

            float radPitch = Math::DegreesToRadians(Pitch);
            float radYaw = Math::DegreesToRadians(Yaw);

            float x = Distance * Math::Cos(radPitch) * Math::Cos(radYaw);
            float y = Distance * Math::Cos(radPitch) * Math::Sin(radYaw);
            float z = Distance * Math::Sin(radPitch);

            FVector newPos = Target + FVector(x, y, z);
            SetActorLocation(newPos);

            FRotator lookDir = (Target - newPos).Rotation();
            SetActorRotation(lookDir);
        }        
    }

    UFUNCTION()
    void AddYaw(float v)
    {
        Yaw += v;
    }

    UFUNCTION()
    void AddPitch(float v)
    {
        Pitch += v;
        Pitch = Math::Clamp(Pitch, -85.0f, 85.0f);
    }

    UFUNCTION()
    void CameraOnFixed()
    {
        Yaw = -90;
        Pitch = 50;
        Distance = 2500;

        float radPitch = Math::DegreesToRadians(Pitch);
        float radYaw = Math::DegreesToRadians(Yaw);

        float x = Distance * Math::Cos(radPitch) * Math::Cos(radYaw);
        float y = Distance * Math::Cos(radPitch) * Math::Sin(radYaw);
        float z = Distance * Math::Sin(radPitch);

        FVector newPos = Target + FVector(x, y, z);
        SetActorLocation(newPos);

        FRotator lookDir = (Target - newPos).Rotation();
        SetActorRotation(lookDir);
    }
}

