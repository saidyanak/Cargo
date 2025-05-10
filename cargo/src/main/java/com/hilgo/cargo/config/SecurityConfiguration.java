package com.hilgo.cargo.config;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.authentication.logout.LogoutHandler;

import lombok.RequiredArgsConstructor;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfiguration{

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final AuthenticationProvider authenticationProvider;
    private final LogoutHandler logoutHandler;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .cors()
            .and()
            .authorizeHttpRequests()
            .requestMatchers("/auth/change","/auth/forgot", "/auth/setPassword").hasAnyAuthority("ROLE_DRIVER", "ROLE_DISTRIBUTOR")
            .requestMatchers("/auth/**",
            		"/v2/api-docs",
            		"/v3/api-docs",
            		"/v3/api-docs/**",
            		"/swagger-resources",
            		"/swagger-resources/**",
            		"/configuration/ui",
            		"/configuration/security",
            		"/swagger-ui/**",
            		"/webjars/**",
            		"/swagger-ui.html").permitAll() 
            .requestMatchers("/distributor/**").hasAuthority("ROLE_DISTRIBUTOR")
            .requestMatchers("/employee/**").hasAuthority("ROLE_EMPLOYEE")
            .anyRequest().authenticated() 
            .and()
            .sessionManagement()
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authenticationProvider(authenticationProvider)
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
        	.logout()
        	.logoutUrl("/auth/logout")
        	.addLogoutHandler(logoutHandler)
        	.logoutSuccessHandler((request, response, authentication) -> SecurityContextHolder.clearContext());

        return http.build();
    }
    
    
    
}
