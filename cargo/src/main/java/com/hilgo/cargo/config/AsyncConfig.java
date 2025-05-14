package com.hilgo.cargo.config;

import java.util.concurrent.Executor;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.AsyncConfigurer;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

@Configuration
@EnableAsync  // Asenkron işlemleri etkinleştirir
public class AsyncConfig implements AsyncConfigurer {

    // Asenkron işlemler için Executor yapılandırması
    @Override
    public Executor getAsyncExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        
        // Thread havuzunun yapılandırması
        executor.setCorePoolSize(10);  // Başlangıçta kullanılacak thread sayısı
        executor.setMaxPoolSize(50);   // Maksimum kullanılabilecek thread sayısı
        executor.setQueueCapacity(100); // Kuyruk kapasitesi
        executor.setThreadNamePrefix("async-task-"); // İşlem isimlerini belirliyoruz
        executor.initialize();
        return executor;  // Asenkron işlemleri yönetecek executor'ı döndürüyoruz
    }
}
