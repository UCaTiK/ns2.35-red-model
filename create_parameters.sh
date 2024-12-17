#!/usr/bin/env bash

# Параметры
DIR="parameters"
Q_START=10
Q_STOP=90
Q_DELTA=1

# Создаем директорию, если она не существует
mkdir -p "$DIR"

# Генерация чисел от Q_START до Q_STOP с шагом Q_DELTA
for Q1 in $(seq $Q_START $Q_DELTA $Q_STOP); do
    for Q2 in $(seq $Q_START $Q_DELTA $Q_STOP); do
        # Условие: Q1 < Q2
        if [ "$Q1" -lt "$Q2" ]; then
            # Формируем имя файла как Q1_Q2
            FILENAME="${DIR}/${Q1}_${Q2}"
            echo "$Q1 $Q2" > "$FILENAME"
        fi
    done
done

