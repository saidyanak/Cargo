package com.hilgo.Exercise_1.repo;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.hilgo.Exercise_1.Entity.User;

public interface UserRepository extends JpaRepository<User, Long>{

	Optional<User> findByUsername(String username);
	boolean existsByEmail(String email);
	Optional<User> findByEmail(String email);
	boolean existsByUsername(String username);
	
}
