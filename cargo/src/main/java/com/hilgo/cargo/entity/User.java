package com.hilgo.cargo.entity;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import com.hilgo.cargo.entity.enums.Roles;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Inheritance(strategy = InheritanceType.JOINED)
public class User implements UserDetails{
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "user_id")
	private Long Id;
	
	@Column
	private String username;
	
	@Column
	private String mail;
	
	@Column
	private String password;
	
	@Column
	private String phoneNumber;
	
	@Enumerated(EnumType.STRING)
	private Roles roles;

	private boolean enable;
    
    private String verificationCode;
    
    private String verificationExpiration; 
    
    private LocalDateTime verificationCodeExpiresAt;
    

	
	@Override
	public Collection<? extends GrantedAuthority> getAuthorities() {
		return List.of(new SimpleGrantedAuthority("ROLE_" + roles.name()));
	}

	@Override
	public String getPassword() {
		return password;
	}

	@Override
	public String getUsername() {
		return username;
	}
	
	 public String getEmail() {
	        return mail;
	    }

	 public void setEmail(String mail) {
       this.mail = mail;
	 	}
	 
	 @Override
	    public boolean isEnabled() {
	        return enable;
	    }
	 
}
