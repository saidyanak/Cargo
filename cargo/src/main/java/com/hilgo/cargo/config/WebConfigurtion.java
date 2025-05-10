package com.hilgo.cargo.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfigurtion implements WebMvcConfigurer{

	@Override
	public void addCorsMappings(CorsRegistry corsRegistry)// frontun erşimi için
	{
		corsRegistry.addMapping("/**").allowedOrigins("*") // Tüm kaynaklar
        .allowedMethods("*");
	}
}
