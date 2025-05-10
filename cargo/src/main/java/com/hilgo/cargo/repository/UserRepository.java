package com.hilgo.cargo.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.hilgo.cargo.entity.User;

@Repository
public interface UserRepository extends JpaRepository<User, Long>{

	Optional<User> findByUsername(String username);
	Optional<User> findByMail(String mail);
	Optional<User> findByPhoneNumber(String phoneNumber);
	boolean existsByUsername(String username);
	boolean existsByMail(String mail);
	boolean existsByPhoneNumber(String phoneNumber);
}
